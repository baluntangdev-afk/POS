package net.nyx.printerservice.print;

import android.os.Parcel;
import android.os.Parcelable;

public class PrintTextFormat implements Parcelable {
    public int textSize = 24;
    public int ali = 0; // 0 = left, 1 = center, 2 = right
    public int style = 0; // 0 = normal, 1 = bold

    public PrintTextFormat() {
    }

    protected PrintTextFormat(Parcel in) {
        textSize = in.readInt();
        ali = in.readInt();
        style = in.readInt();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(textSize);
        dest.writeInt(ali);
        dest.writeInt(style);
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<PrintTextFormat> CREATOR = new Creator<PrintTextFormat>() {
        @Override
        public PrintTextFormat createFromParcel(Parcel in) {
            return new PrintTextFormat(in);
        }

        @Override
        public PrintTextFormat[] newArray(int size) {
            return new PrintTextFormat[size];
        }
    };
}
