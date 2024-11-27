MODULE ArrayWriter;

IMPORT Files, Out;

PROCEDURE WriteArrayToFile*(arr: ARRAY OF CHAR; filename: ARRAY OF CHAR);
VAR
  file: Files.File;
  r: Files.Rider;
  i: INTEGER;
BEGIN
  (* Create a new file *)
  file := Files.New(filename);
  IF file = NIL THEN
    Out.String("Error: Could not create file."); Out.Ln;
    RETURN;
  END;
  Files.Set(r, file, 0);
  (* Write each character from the array to the file *)
  i := 0;
  WHILE (i < LEN(arr)) & (arr[i] # 0X) DO
    Files.WriteBytes(r,(ORD(arr[i])));
    INC(i);
  END;

  (* Close the file *)
  Files.Register(file);
  Files.Close(file);
  Out.String("File written successfully to "); Out.String(filename); Out.Ln;
END WriteArrayToFile;

PROCEDURE Test*;
VAR
  testArray: ARRAY 3 OF CHAR;
BEGIN
  testArray := "ab";
  WriteArrayToFile(testArray, "output.md");
END Test;

BEGIN
  Out.String("ArrayWriter module initialized."); Out.Ln;
  Test;
END ArrayWriter.
