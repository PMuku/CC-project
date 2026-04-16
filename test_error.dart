void main() {
    // Error 1: missing semicolon after declaration
    int x = 5
    double y = 3.14;

    // Error 2: if condition missing parentheses
    if x > 3 {
        x = x + 1;
    }

    // Error 3: while body missing braces (not a block)
    while (x < 10)
        x = x + 1;

    // Error 4: incomplete expression before semicolon
    y = y + ;
}
