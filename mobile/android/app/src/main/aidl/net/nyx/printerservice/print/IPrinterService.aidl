package net.nyx.printerservice.print;

import net.nyx.printerservice.print.PrintTextFormat;

interface IPrinterService {
    int printText(String text, in PrintTextFormat textFormat);
    int printTableText(in String[] texts, in int[] weights, in PrintTextFormat[] formats);
    int paperOut(int px);
    int getPrinterStatus();
}
