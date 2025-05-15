MODULE SPARTAN;

IMPORT IntStr := oocIntStr, Strings, Files, Out, Internet, strTypes, strUtils, dynamicarray;

CONST
  defName* = "defaultname.gmi";
  defEOL = "0DX0AX"; (* CRLF end of line *)

TYPE
  transport* = POINTER TO transportDesc;
  transportDesc* = RECORD END;

  bsdSocket* = POINTER TO bsdSocketDesc;
  bsdSocketDesc = RECORD(transportDesc)
    socket : Internet.Socket
  END;

  Client* = POINTER TO ClientDesc;

  ClientDesc* = RECORD
    host*, port*, path*: strTypes.pstring;
    connectionFlag*: BOOLEAN;
    trn*: transport;
    rspnBody*: strTypes.pstring;
    header-: strTypes.pstring;
    statusCode: INTEGER;
    rspnFirstLine*: strTypes.pstring;
    contentLength*: LONGINT;
    eol*: ARRAY 2 OF CHAR;
    null*: ARRAY 1 OF CHAR;
    dyno: dynamicarray.dynamicarray;
    Create*: PROCEDURE(host, port, path: ARRAY OF CHAR): Client;
    Get*: PROCEDURE(spartan: Client): strTypes.pstring;
    clearState*: PROCEDURE(VAR spartan: Client);
    Connect*: PROCEDURE(VAR spartan: Client): BOOLEAN;
    Disconnect*: PROCEDURE(VAR spartan: Client);
    Write*: PROCEDURE(VAR spartan: Client; request: ARRAY OF CHAR): BOOLEAN;
    Read*: PROCEDURE(VAR spartan: Client; VAR buffer: ARRAY OF CHAR): BOOLEAN;
    Dynomaker: PROCEDURE(VAR spartan: Client): dynamicarray.dynamicarray;
    Save*: PROCEDURE(VAR spartan: Client; name: ARRAY OF CHAR);
  END;

PROCEDURE clearState*(VAR spartan: Client);
BEGIN
  spartan^.rspnBody := NIL;
  spartan^.header := NIL;
  spartan^.rspnFirstLine := NIL;
  spartan^.contentLength := 0;
END clearState;

PROCEDURE dynomaker(VAR spartan: Client): dynamicarray.dynamicarray;
BEGIN
  RETURN dynamicarray.Create();
END dynomaker;

PROCEDURE saver(VAR spartan: Client; name: ARRAY OF CHAR);
BEGIN
  IF spartan^.dyno^.size <= 0 THEN
    Out.String("No data to save or already saved"); Out.Ln;
    RETURN;
  END;

  dynamicarray.writetofile(spartan^.dyno, name);
  spartan^.dyno^.size := 0; 
END saver;

PROCEDURE connector(VAR spartan: Client): BOOLEAN;
BEGIN
  spartan^.connectionFlag := FALSE;
  IF spartan^.trn IS bsdSocket THEN
    spartan^.connectionFlag := Internet.Connect(spartan^.host^, spartan^.port^, spartan^.trn(bsdSocket).socket);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    HALT(5);
  END;
  RETURN spartan^.connectionFlag;
END connector;

PROCEDURE disconnector(VAR spartan: Client);
BEGIN
  IF spartan^.trn IS bsdSocket THEN
    Internet.Disconnect(spartan^.trn(bsdSocket).socket);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    HALT(5);
  END;
END disconnector;

PROCEDURE writer(VAR spartan: Client; request: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF spartan^.trn IS bsdSocket THEN
    RETURN Internet.Write(spartan^.trn(bsdSocket).socket, request);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END writer;

PROCEDURE readbuffer(VAR spartan: Client; VAR buf: ARRAY OF CHAR; VAR i: LONGINT): BOOLEAN;
BEGIN
  IF spartan^.trn IS bsdSocket THEN
    i := 0;
    IF Internet.ReadBuf(spartan^.trn(bsdSocket).socket, buf, i) THEN
      RETURN TRUE;
    ELSE
      i := 0;
      RETURN FALSE;
    END;
  ELSE
    Out.String("spartan is not initialized with bsdSocket"); Out.Ln;
    RETURN FALSE;
  END;
END readbuffer;

PROCEDURE reader(VAR spartan: Client; VAR buffer: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF spartan^.trn IS bsdSocket THEN
    RETURN Internet.Read(spartan^.trn(bsdSocket).socket, buffer);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END reader;

PROCEDURE buildRequest*(spartan: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  len: INTEGER;
BEGIN
  len := Strings.Length(spartan^.host^) + Strings.Length(spartan^.path^) + 5; (* +5 for spaces, "0", CRLF *)
  NEW(req, len);

  COPY(spartan^.host^, req^);
  Strings.Append(" ", req^);
  Strings.Append(spartan^.path^, req^);
  Strings.Append(" 0", req^); (* "0" indicates no body content *)
  Strings.Append(spartan^.eol, req^);
  RETURN req;
END buildRequest;

PROCEDURE parseHeader(VAR spartan: Client; VAR str: ARRAY OF CHAR);
VAR
  i: INTEGER;
BEGIN
    Out.String("header is: '"); Out.String(str); Out.String("'"); Out.Ln;
  i := 0;
  REPEAT
    IF (str[i] >= '0') & (str[i] <= '9') THEN
       spartan^.statusCode := ORD(str[i]) - ORD('0');
           Out.String("set status code:"); Out.Int(spartan^.statusCode, 0); Out.Ln;
    END;
    INC(i);
  UNTIL i = LEN(str);
END parseHeader;

PROCEDURE zeroBuf(VAR str: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE i < LEN(str) DO
    str[i] := 0X;
    INC(i);
  END;
END zeroBuf;

PROCEDURE readTillCRLF(spartan: Client);
VAR
  buf: ARRAY 2 OF CHAR;
  hdr: ARRAY 256 OF CHAR;
  b: BOOLEAN;
  i: INTEGER;
BEGIN
  COPY("", hdr); i := 0;
  REPEAT
    b := Internet.ReadBytes(spartan^.trn(bsdSocket).socket, buf, 1);
      IF b THEN
        IF buf[0] # 0DX THEN
          hdr[i] := buf[0];
          INC(i);
        END;
        Out.String("have read one byte: '"); Out.Char(buf[0]);
        Out.String("'"); Out.Ln;
      ELSE
         Out.String("failed to read"); Out.Ln; HALT(2);
      END;
  UNTIL buf[0] = 0DX;
  hdr[i] := 0X;
  b := Internet.ReadBytes(spartan^.trn(bsdSocket).socket, buf, 1);
  IF b THEN
    IF buf[0] # 0AX THEN
      Out.String("0AX expected, got: "); Out.Int(ORD(buf[0]), 0);
      Out.Ln; HALT(1);
    END;
  ELSE
    Out.String("failed to read"); Out.Ln; HALT(3)
  END;
  NEW(spartan^.header, Strings.Length(hdr)+1);
  COPY(hdr, spartan^.header^);
  parseHeader(spartan, spartan^.header^);
END readTillCRLF;

PROCEDURE extractFilename(path: ARRAY OF CHAR; VAR filename: ARRAY OF CHAR);
VAR
  i, j, len, lastSlash: LONGINT;
BEGIN
  filename[0] := 0X;
  len := 0;
  WHILE (len < LEN(path)) & (path[len] # 0X) DO
    INC(len);
  END;
  lastSlash := -1;
  FOR i := 0 TO len-1 DO
    IF path[i] = '/' THEN
      lastSlash := i;
    END;
  END;

  IF lastSlash >= 0 THEN
    j := 0;
    FOR i := lastSlash + 1 TO len-1 DO
      IF j < LEN(filename)-1 THEN
        filename[j] := path[i];
        INC(j);
      END;
    END;
    filename[j] := 0X;
  END;

  IF filename[0] = 0X THEN
    COPY(defName, filename);
    Out.String("Using default filename: "); Out.String(filename); Out.Ln;
    RETURN;
  END;

  i := 0;
  WHILE (i < LEN(filename)) & (filename[i] # 0X) DO
    IF (ORD(filename[i]) < 32) OR (filename[i] = ':') OR (filename[i] = '*') OR
       (filename[i] = '?') OR (filename[i] = '"') OR (filename[i] = '<') OR
       (filename[i] = '>') OR (filename[i] = '|') OR (ORD(filename[i]) = 127) THEN
      filename[i] := '_';
    END;
    INC(i);
  END;

  Out.String("Extracted filename: "); Out.String(filename); Out.Ln;
END extractFilename;

PROCEDURE get*(spartan: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  buf: ARRAY 4096 OF CHAR; 
  i, j, totalBytes: LONGINT;
  b: BOOLEAN;
  saveFilename: ARRAY 256 OF CHAR;
          tmp: POINTER TO ARRAY OF CHAR;
          oldSize, k: LONGINT;
          file: Files.File;
          r: Files.Rider;
BEGIN
  spartan^.clearState(spartan);
  totalBytes := 0;

  IF (spartan^.path # NIL) & (spartan^.path^[0] # 0X) THEN
    COPY(spartan^.path^, saveFilename);
    IF saveFilename[0] = '/' THEN
      i := 0;
      WHILE saveFilename[i+1] # 0X DO
        saveFilename[i] := saveFilename[i+1];
        INC(i);
      END;
      saveFilename[i] := 0X;
    END;
  ELSE
    COPY("download.bin", saveFilename);
  END;

  Out.String("Will save as: "); Out.String(saveFilename); Out.Ln;

  IF ~spartan.Connect(spartan) THEN
    Out.String("Connection failed"); Out.Ln;
    HALT(5);
  END;

  req := buildRequest(spartan);
  IF ~writer(spartan, req^) THEN
    Out.String("Failed to send request"); Out.Ln;
    HALT(5);
  END;

  readTillCRLF(spartan);
  Out.String("Header received, status: "); Out.Int(spartan^.statusCode, 0); Out.Ln;
  spartan^.dyno := dynamicarray.Create();
  Out.String("Downloading...");
  REPEAT
    i := 0; 
    b := Internet.ReadBuf(spartan^.trn(bsdSocket).socket, buf, i);

    IF b & (i > 0) THEN
      spartan^.dyno^.size := totalBytes + i;  (* Grow size *)
      IF spartan^.dyno^.content = NIL THEN
        NEW(spartan^.dyno^.content, i);
        FOR j := 0 TO i - 1 DO
          spartan^.dyno^.content^[j] := buf[j];
        END;
      ELSE
          oldSize := totalBytes;
          NEW(tmp, oldSize);
          FOR k := 0 TO oldSize - 1 DO
            tmp^[k] := spartan^.dyno^.content^[k];
          END;
          NEW(spartan^.dyno^.content, oldSize + i);
          FOR k := 0 TO oldSize - 1 DO
            spartan^.dyno^.content^[k] := tmp^[k];
          END;
          FOR k := 0 TO i - 1 DO
            spartan^.dyno^.content^[oldSize + k] := buf[k];
          END;
        END;
      END;

      totalBytes := totalBytes + i;
      Out.Char('.');
  UNTIL ~b OR (i = 0);

  Out.Ln;
  Out.String("Total bytes downloaded: "); Out.Int(totalBytes, 0); Out.Ln;
  NEW(spartan^.rspnBody, totalBytes + 1);
  FOR i := 0 TO totalBytes - 1 DO
    spartan^.rspnBody^[i] := spartan^.dyno^.content^[i];
  END;
  spartan^.rspnBody^[totalBytes] := 0X;
  file := Files.New(saveFilename);
  IF file # NIL THEN
    Files.Set(r, file, 0);
    FOR i := 0 TO totalBytes - 1 DO
      Files.Write(r, spartan^.dyno^.content^[i]);
    END;
    Files.Register(file);
    Files.Close(file);
    Out.String("File saved: "); Out.String(saveFilename); Out.Ln;
  ELSE
    Out.String("Failed to create file"); Out.Ln;
  END;

  spartan.Disconnect(spartan);
  RETURN spartan^.rspnBody;
END get;

PROCEDURE Create*(host, port, path: ARRAY OF CHAR): Client;
VAR
  spartan: Client;
  socket: bsdSocket;
  newPath: ARRAY 512 OF CHAR;
BEGIN
  NEW(spartan);
  spartan^.eol[0] := 0DX; spartan^.eol[1] := 0AX; spartan^.null[0] := 0X;
  strUtils.string2pstring(host, spartan^.host);
  strUtils.string2pstring(port, spartan^.port);
  IF Strings.Length(path) = 0 THEN
    strUtils.string2pstring("/", spartan^.path);
    Out.String("Empty path detected, using '/' as default"); Out.Ln;
  ELSE
    IF path[0] # '/' THEN
        newPath[0] := '/';
        Strings.Append(path, newPath);
        strUtils.string2pstring(newPath, spartan^.path);
        Out.String("Path normalized to start with '/'"); Out.Ln;
    ELSE
      strUtils.string2pstring(path, spartan^.path);
    END;
  END;
  spartan^.contentLength := 0;
  spartan^.Create := Create;
  spartan^.Get := get;
  spartan^.clearState := clearState;

  NEW(socket);
  spartan^.trn := socket;
  spartan^.Connect := connector;
  spartan^.Disconnect := disconnector;
  spartan^.Write := writer;
  spartan^.Read := reader;
  spartan^.Dynomaker := dynomaker;
  spartan^.Save := saver;
  RETURN spartan;
END Create;

END SPARTAN.
