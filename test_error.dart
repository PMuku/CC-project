void main() {
    int x = 5@;          // @ is invalid
    double y = 3.14.5;   // malformed number
    String str = "unclosed;  // unclosed string
    if (x >> 3) {        // >> not in language
        x = x +++ 2;     // +++ invalid
    }
}