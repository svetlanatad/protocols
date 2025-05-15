MODULE dynamicarray;

IMPORT Out, Files, Strings;

TYPE dynamicarray* = POINTER TO DynamicarrayDesc;
dynarray* = RECORD
END;

DynamicarrayDesc* = RECORD(dynarray)
  (*size is how many elements*)
  size*: LONGINT;
  (*capacity is how many elements it can hold*)
  capacity*: LONGINT;
  content*: POINTER TO ARRAY OF CHAR;
        appender-: PROCEDURE (a: dynamicarray; str: ARRAY OF CHAR);
END;

VAR
  quietMode*: BOOLEAN;

PROCEDURE writetofile*(VAR arr: dynamicarray; name: ARRAY OF CHAR);
VAR
  file: Files.File;
  r: Files.Rider;
  i, dataSize: LONGINT;
BEGIN
  dataSize := arr^.size;
  IF dataSize <= 0 THEN
    Out.String("Warning: No data to write for file: "); Out.String(name); Out.Ln;
    RETURN;
  END;

  Out.String("Writing file, data size: "); Out.Int(dataSize, 0); Out.Ln;

  file := Files.New(name);
  IF file # NIL THEN
    Files.Set(r, file, 0);
    FOR i := 0 TO dataSize - 1 DO
      Files.Write(r, arr^.content^[i]);
    END;

    Files.Register(file);
    Files.Close(file);
    Out.String("File saved successfully: "); Out.String(name); Out.Ln;
  ELSE
    Out.String("Error: Could not create file "); Out.String(name); Out.Ln;
  END;
END writetofile;

PROCEDURE copy(VAR src, dst: ARRAY OF CHAR);
VAR
  i: LONGINT;
BEGIN
  IF LEN(src) <= LEN(dst) THEN
     i := 0;
       Out.String("good. source length is smaller than or equal to the destination length"); Out.Ln;

     REPEAT
       IF src[i] = 0X THEN
         dst[i] := src[i];
         Out.String("curr char: "); Out.Char(dst[i]); Out.Ln;
         Out.String("overwritten something from source to dest as it was null"); Out.Ln;
        ELSE (*if it is not null *)
   Out.String("current iter count: "); Out.Int(i,0); Out.Ln;
         dst[i] := src[i];
         Out.String("curr char: "); Out.Char(dst[i]); Out.Ln;
         Out.String("copied something from source to the end of the arr as it was not null"); Out.Ln;
     END;
     INC(i);
     UNTIL i = LEN(src);
     Out.String("Whats the iterator count now? The size? Source LEN: "); Out.Int(i, 0); Out.Ln;
   ELSE
      Out.String("copy source, destination: error: destination length needs to be >= src length"); Out.Ln; HALT(0);
   END;
END copy;

PROCEDURE ReallocAndAppendinky(arr: dynamicarray; str: ARRAY OF CHAR);
VAR
  tmp: POINTER TO ARRAY OF CHAR;
BEGIN
  Out.String("current array content len: "); Out.Int(LEN(arr^.content^), 0); Out.Ln;
  NEW(tmp, LEN(arr^.content^));
  Out.String("allocated memory for tmp arr with arr content size"); Out.Ln;
  copy(arr^.content^, tmp^);
  Out.String("copied the arr content into the tmp content"); Out.Ln;
  NEW(arr^.content, LEN(tmp^) + LEN(str) + 1);
  arr^.size := LEN(str);
  arr^.capacity := arr^.capacity + LEN(str) + 1;
  Out.String("Array size now: "); Out.Int(arr^.size, 0); Out.Ln;
  Out.String("LEN array content size: "); Out.Int(LEN(arr^.content^), 0); Out.Ln;
  Out.String("Array capacitynow: "); Out.Int(arr^.capacity, 0); Out.Ln;
  copy(tmp^, arr^.content^);
  Out.String("copied the tmp content bakc into the array content after reallocation"); Out.Ln;
  Out.String("trying to copy the string into the array"); Out.Ln;
  copy(str, arr^.content^);
  Out.String("trying to assign 0X to the last element of arr"); Out.Ln;
  arr^.content^[LEN(tmp^) + LEN(str)] := 0X; Out.String("assigned complete"); Out.Ln
END ReallocAndAppendinky;

PROCEDURE dumpArray(VAR str: ARRAY OF CHAR);
VAR
  i, l: LONGINT;
BEGIN
  i := 0; l := Strings.Length(str);
  REPEAT
    Out.String("str["); Out.Int(i, 0); Out.String("]='"); Out.Char(str[i]); Out.String("'"); Out.Ln;
    INC(i);
  UNTIL i = l;
END dumpArray;
PROCEDURE copylarr0t(VAR src: ARRAY OF CHAR; VAR dst: ARRAY OF CHAR; VAR start: LONGINT);
(*its corrupted. it works if you have c optimization enabled, but its not good. dont use. i may think of this later*)
VAR
i: LONGINT;
j: LONGINT;
s: LONGINT;
d: LONGINT;
BEGIN
  i := start;
  j := 0;
  s := LEN(src);
  d := LEN(dst);
  Out.String("len of src is: "); Out.Int(s, 0); Out.Ln;
  Out.String("len of dst is: "); Out.Int(d, 0); Out.Ln;
  IF dst[i] = 0X THEN
     Out.String("dst[i] is 0X")
  ELSIF dst[i] = 0AX THEN
     Out.String("dst[i] is 0A")
  ELSIF dst[i] = 0DX THEN
     Out.String("dst[i] is 0D")
  ELSE
     Out.String("before assignment dst["); Out.Int(i, 0); Out.String("]='"); Out.Char(dst[i]); Out.String("'"); Out.Ln;
  END;
  Out.Ln;
  IF i = 0 THEN
     REPEAT
       dst[i] := src[i];
       IF src[i] = 0X THEN
         Out.String("src["); Out.Int(i, 0); Out.String("]='0X'");
       ELSIF src[i] = 0AX THEN
         Out.String("src["); Out.Int(i, 0); Out.String("]='0AX'");
       ELSIF src[i] = 0DX THEN
         Out.String("src["); Out.Int(i, 0); Out.String("]='0DX'");
       ELSE
         Out.String("src["); Out.Int(i, 0); Out.String("]='"); Out.Char(src[i]); Out.String("'"); Out.Ln;
       END;
       Out.String("dst["); Out.Int(i, 0); Out.String("]='"); Out.Char(dst[i]); Out.String("'"); Out.Ln;
       INC(i);
     UNTIL i = LEN(src) - 1;
  ELSE
       Out.String("current index i am trying to assign is: "); Out.Int(i, 0); Out.Ln;
     REPEAT
       IF src[j] = 0X THEN
         Out.String("src["); Out.Int(j, 0); Out.String("]='0X'");
       ELSIF src[j] = 0AX THEN
         Out.String("src["); Out.Int(j, 0); Out.String("]='0AX'");
       ELSIF src[j] = 0DX THEN
         Out.String("src["); Out.Int(j, 0); Out.String("]='0DX'");
       ELSE
         Out.String("hmmm"); Out.Ln;
         Out.String("src["); Out.Int(j, 0); Out.String("]='"); Out.Char(src[j]); Out.String("'"); Out.Ln;
       END;
      Out.String("assigning"); Out.Ln;
      dst[i] := src[j];
      Out.String("assigned"); Out.Ln;
      Out.String("src["); Out.Int(j, 0); Out.String("]='"); Out.Char(src[j]); Out.String("'"); Out.Ln;
      Out.String("dst["); Out.Int(i, 0); Out.String("]='"); Out.Char(dst[i]); Out.String("'"); Out.Ln;
      INC(i);
      INC(j);
      Out.String("i="); Out.Int(i, 0); Out.Ln;
      Out.String("j="); Out.Int(j, 0); Out.Ln;
      Out.String("LEN(dst)="); Out.Int(LEN(dst), 0); Out.Ln;
      Out.String("src='"); Out.String(src); Out.String("'"); Out.Ln; Out.Ln; Out.Ln;
      dumpArray(dst);
      Out.String("dst='"); Out.String(dst); Out.String("'"); Out.Ln; Out.Ln;
     UNTIL i = LEN(dst) - 2;
       Out.String("exited the loop"); Out.Ln;
  END;
  Out.String("The last index probably is: "); Out.Int(i, 0); Out.Ln;
  dst[i] := 0X;
END copylarr0t;

PROCEDURE ReallocAndAppend(arr: dynamicarray; str: ARRAY OF CHAR);
VAR
  tmp: POINTER TO ARRAY OF CHAR;
  i, j, strLen, oldSize: LONGINT;
BEGIN
  strLen := 0;
  WHILE (strLen < LEN(str)) & (str[strLen] # 0X) DO
    INC(strLen);
  END;
  IF strLen = 0 THEN RETURN; END;
  oldSize := arr^.size;
  NEW(tmp, oldSize);
  FOR i := 0 TO oldSize - 1 DO
    tmp^[i] := arr^.content^[i];
  END;
  NEW(arr^.content, oldSize + strLen);
  FOR i := 0 TO oldSize - 1 DO
    arr^.content^[i] := tmp^[i];
  END;
  FOR j := 0 TO strLen - 1 DO
    arr^.content^[oldSize + j] := str[j];
  END;
  arr^.size := oldSize + strLen;
  arr^.capacity := oldSize + strLen;
  Out.String("Appended "); Out.Int(strLen, 0);
  Out.String(" bytes. Total size now: "); Out.Int(arr^.size, 0); Out.Ln;
END ReallocAndAppend;

PROCEDURE Append*(arr: dynamicarray; str: ARRAY OF CHAR);
VAR
  i, strLen: LONGINT;
BEGIN
  strLen := LEN(str);
  IF arr.content = NIL THEN
    NEW(arr.content, strLen + 1);
    FOR i := 0 TO strLen - 1 DO
      IF i < LEN(arr.content^) THEN
        arr.content^[i] := str[i];
      END;
    END;
    IF strLen < LEN(arr.content^) THEN
      arr.content^[strLen] := 0X;
    END;
    arr.size := strLen;
    arr.capacity := LEN(arr.content^);
  ELSE
    ReallocAndAppend(arr, str);
  END;
END Append;

PROCEDURE Init*(arr: dynamicarray; size: LONGINT);
VAR
  i: LONGINT;
BEGIN
  Out.String("capacity during initialization: "); Out.Int(arr.capacity, 0); Out.Ln;
  Out.String("size during initialization: "); Out.Int(arr.size, 0); Out.Ln;
  NEW(arr.content, size);
  arr.size := size;
  arr.capacity := size;
  i := 0;
  REPEAT
    arr.content^[i] := 0X;
    INC(i);
  UNTIL i = size;
  Out.String("capacity after initialization: "); Out.Int(arr.capacity, 0); Out.Ln;
  Out.String("size after initialization: "); Out.Int(arr.size, 0); Out.Ln;
END Init;

PROCEDURE Create*(): dynamicarray;
VAR
  arr: dynamicarray;
BEGIN
  NEW(arr);
  arr.content := NIL;
  arr.size := 0;
  arr.capacity := 0;
  arr.appender := Append;
  RETURN arr;
END Create;


PROCEDURE Resize*(arr: dynamicarray): dynamicarray;
VAR
  i: LONGINT;
  newarr: dynamicarray;
BEGIN
  NEW(newarr);
  NEW(newarr.content, 2 * arr.capacity);
  i := 0;
  REPEAT
    newarr.content^[i] := arr.content^[i];
  UNTIL i = arr.size;
  newarr.size := arr.size;
  newarr.capacity := 2 * arr.capacity;
  RETURN newarr;
END Resize;

BEGIN
  quietMode := TRUE

END dynamicarray.
