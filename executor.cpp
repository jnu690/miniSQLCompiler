#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <map>

using namespace std;

// Store parsed query info
struct Query {
    vector<string> columns;
    string table;
    string whereCondition;
};

Query currentQuery;

// Split string by delimiter
vector<string> split(const string& str, char delim) {
    vector<string> tokens;
    stringstream ss(str);
    string token;
    while (getline(ss, token, delim)) {
        tokens.push_back(token);
    }
    return tokens;
}

// Trim whitespace
string trim(const string& str) {
    size_t start = str.find_first_not_of(" \t\r\n");
    size_t end = str.find_last_not_of(" \t\r\n");
    if (start == string::npos) return "";
    return str.substr(start, end - start + 1);
}

// Evaluate a simple condition
bool evalCondition(const map<string, string>& row, const string& cond) {
    string c = trim(cond);
    
    // Remove outer parentheses if present
    if (c[0] == '(' && c[c.length()-1] == ')') {
        c = c.substr(1, c.length()-2);
        c = trim(c);
    }
    
    // Handle AND
    size_t andPos = c.find(" AND ");
    if (andPos != string::npos) {
        string left = c.substr(0, andPos);
        string right = c.substr(andPos + 5);
        return evalCondition(row, left) && evalCondition(row, right);
    }
    
    // Handle OR
    size_t orPos = c.find(" OR ");
    if (orPos != string::npos) {
        string left = c.substr(0, orPos);
        string right = c.substr(orPos + 4);
        return evalCondition(row, left) || evalCondition(row, right);
    }
    
    // Simple comparison
    string op;
    size_t opPos;
    
    if ((opPos = c.find(">=")) != string::npos) op = ">=";
    else if ((opPos = c.find("<=")) != string::npos) op = "<=";
    else if ((opPos = c.find("==")) != string::npos) op = "==";
    else if ((opPos = c.find("!=")) != string::npos) op = "!=";
    else if ((opPos = c.find(">")) != string::npos) op = ">";
    else if ((opPos = c.find("<")) != string::npos) op = "<";
    else return true;
    
    string colName = trim(c.substr(0, opPos));
    string value = trim(c.substr(opPos + op.length()));
    
    // Remove quotes from string literals
    if (value[0] == '\'' || value[0] == '"') {
        value = value.substr(1, value.length()-2);
    }
    
    if (row.find(colName) == row.end()) return false;
    string rowValue = row.at(colName);
    
    // Try numeric comparison
    try {
        int rowInt = stoi(rowValue);
        int valInt = stoi(value);
        
        if (op == ">") return rowInt > valInt;
        if (op == "<") return rowInt < valInt;
        if (op == ">=") return rowInt >= valInt;
        if (op == "<=") return rowInt <= valInt;
        if (op == "==") return rowInt == valInt;
        if (op == "!=") return rowInt != valInt;
    } catch (...) {
        // String comparison
        if (op == "==") return rowValue == value;
        if (op == "!=") return rowValue != value;
    }
    
    return false;
}

// Execute the query
void executeQuery() {
    string filename = currentQuery.table;
    
    // If no .csv extension, add it (for local files)
    if (filename.find(".csv") == string::npos) {
        filename += ".csv";
    }
    
    ifstream file(filename);
    
    if (!file.is_open()) {
        cerr << "\nError: Cannot open file '" << filename << "'\n";
        return;
    }
    
    string headerLine;
    getline(file, headerLine);
    vector<string> headers = split(headerLine, ',');
    
    // Trim headers
    for (auto& h : headers) h = trim(h);
    
    // Determine which columns to display
    vector<string> displayCols;
    if (currentQuery.columns.size() == 1 && currentQuery.columns[0] == "*") {
        displayCols = headers;
    } else {
        displayCols = currentQuery.columns;
    }
    
    // Print header
    cout << "\n";
    cout << "+";
    for (size_t i = 0; i < displayCols.size(); i++) {
        cout << "-----------------";
        if (i < displayCols.size() - 1) cout << "+";
    }
    cout << "+\n|";
    
    for (const auto& col : displayCols) {
        printf(" %-15s |", col.c_str());
    }
    
    cout << "\n+";
    for (size_t i = 0; i < displayCols.size(); i++) {
        cout << "-----------------";
        if (i < displayCols.size() - 1) cout << "+";
    }
    cout << "+\n";
    
    // Process rows
    int count = 0;
    string line;
    while (getline(file, line)) {
        vector<string> values = split(line, ',');
        
        // Create row map
        map<string, string> row;
        for (size_t i = 0; i < headers.size() && i < values.size(); i++) {
            row[headers[i]] = trim(values[i]);
        }
        
        // Check WHERE condition
        if (!currentQuery.whereCondition.empty()) {
            if (!evalCondition(row, currentQuery.whereCondition)) {
                continue;
            }
        }
        
        // Print row
        cout << "|";
        for (const auto& col : displayCols) {
            string val = row[col];
            printf(" %-15s |", val.c_str());
        }
        cout << "\n";
        count++;
    }
    
    // Print footer
    cout << "+";
    for (size_t i = 0; i < displayCols.size(); i++) {
        cout << "-----------------";
        if (i < displayCols.size() - 1) cout << "+";
    }
    cout << "+\n";
    
    cout << "\nSuccess: " << count << " row(s) returned\n\n";
    
    file.close();
}


