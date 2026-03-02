void main() {
    int x = 5;
    double y = 3.14;
    bool flag = true;
    String s = "hello";

    x = x + 2 * (3 + 1);
    y = (y + x) / 2.0;

    if (x >= 10 && !flag) {
        y = y * 2;
    } else {
        y = y / 2;
    }

    while (x < 15) {
        x = x + 1;
    }
}