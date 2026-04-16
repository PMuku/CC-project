void main() {
    // Variable declarations with initialisation
    int x = 5;
    double y = 3.14;
    bool flag = true;
    String msg = "hello";

    // Simple assignment
    x = x + 2 * (3 + 1);
    y = (y + x) / 2.0;

    // if-else with nested logical/relational expressions
    if (x >= 10 && !flag) {
        y = y * 2.0;
    } else {
        y = y / 2.0;
    }

    // Chained if-else-if
    if (x == 0) {
        x = 1;
    } else if (x < 5) {
        x = x + 10;
    } else {
        x = x - 1;
    }

    // while loop
    while (x < 20) {
        x = x + 1;
    }

    // var declaration + compound expression
    var z = x + y;
    bool result = (x == 10) || (flag != false);
}
