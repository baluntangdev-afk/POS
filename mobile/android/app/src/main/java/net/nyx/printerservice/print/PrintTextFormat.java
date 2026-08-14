package net.nyx.printerservice.print;

import android.os.Parcel;
import android.os.Parcelable;

// Field layout, Parcel wire order, and semantics reverse-engineered from the
// installed net.nyx.printerservice APK (v1.3.3) and the manufacturer's own
// postest diagnostic app via dexdump. The real class has 12 fields; textSize
// is field 0, align is field 8, and bold/style is field 9 — confirmed by
// disassembling postest's own PrintTextFormat setter methods, which write to
// exactly those field positions. The other fields are left at their observed
// defaults since postest never touches them for text printing.
public class PrintTextFormat implements Parcelable {
    public int textSize = 24;
    public boolean underline = false;
    public float scaleX = 1.0f;
    public float scaleY = 1.0f;
    public float letterSpacing = 0f;
    public float lineSpacing = 0f;
    public int reserved1 = 0;
    public int reserved2 = 0;
    public int ali = 0; // 0 = left, 1 = center, 2 = right
    public int style = 0; // 0 = normal, 1 = bold
    public int reserved3 = 0;
    public String fontFamily = null;

    public PrintTextFormat() {
    }

    protected PrintTextFormat(Parcel in) {
        textSize = in.readInt();
        underline = in.readByte() != 0;
        scaleX = in.readFloat();
        scaleY = in.readFloat();
        letterSpacing = in.readFloat();
        lineSpacing = in.readFloat();
        reserved1 = in.readInt();
        reserved2 = in.readInt();
        ali = in.readInt();
        style = in.readInt();
        reserved3 = in.readInt();
        fontFamily = in.readString();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(textSize);
        dest.writeByte((byte) (underline ? 1 : 0));
        dest.writeFloat(scaleX);
        dest.writeFloat(scaleY);
        dest.writeFloat(letterSpacing);
        dest.writeFloat(lineSpacing);
        dest.writeInt(reserved1);
        dest.writeInt(reserved2);
        dest.writeInt(ali);
        dest.writeInt(style);
        dest.writeInt(reserved3);
        dest.writeString(fontFamily);
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
