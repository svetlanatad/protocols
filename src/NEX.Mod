MODULE NEX;

IMPORT IntStr := oocIntStr, Strings, Files, Out, Internet, strTypes, strUtils, dynamicarray;

CONST
  defName = "defaultname.gmi";
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
    rspnFirstLine*: strTypes.pstring;
    contentLength*: LONGINT;
    eol*: ARRAY 2 OF CHAR;
    null*: ARRAY 1 OF CHAR;
    dyno: dynamicarray.dynamicarray;
    Create*: PROCEDURE(host, port, path: ARRAY OF CHAR): Client;
    Get*: PROCEDURE(nex: Client): strTypes.pstring;
    clearState*: PROCEDURE(VAR nex: Client);
    Connect*: PROCEDURE(VAR nex: Client): BOOLEAN;
    Disconnect*: PROCEDURE(VAR nex: Client);
    Write*: PROCEDURE(VAR nex: Client; request: ARRAY OF CHAR): BOOLEAN;
    Read*: PROCEDURE(VAR nex: Client; VAR buffer: ARRAY OF CHAR): BOOLEAN;
    Dynomaker: PROCEDURE(VAR nex: Client): dynamicarray.dynamicarray;
    Save*: PROCEDURE(VAR nex: Client; name: ARRAY OF CHAR);
  END;

PROCEDURE clearState*(VAR nex: Client);
BEGIN
  nex^.rspnBody := NIL;
  nex^.rspnFirstLine := NIL;
  nex^.contentLength := 0;
END clearState;

PROCEDURE dynomaker(VAR nex: Client): dynamicarray.dynamicarray;
BEGIN
RETURN dynamicarray.Create();
END dynomaker;

PROCEDURE saver(VAR nex: Client; name: ARRAY OF CHAR);
BEGIN
  dynamicarray.writetofile(nex^.dyno, name);
END saver;

PROCEDURE connector(VAR nex: Client): BOOLEAN;
BEGIN
  nex^.connectionFlag := FALSE;
  IF nex^.trn IS bsdSocket THEN
    nex^.connectionFlag := Internet.Connect(nex^.host^, nex^.port^, nex^.trn(bsdSocket).socket);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    HALT(5);
  END;
  RETURN nex^.connectionFlag;
END connector;

PROCEDURE disconnector(VAR nex: Client);
BEGIN
  IF nex^.trn IS bsdSocket THEN
    Internet.Disconnect(nex^.trn(bsdSocket).socket);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    HALT(5);
  END;
END disconnector;

PROCEDURE writer(VAR nex: Client; request: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF nex^.trn IS bsdSocket THEN
    RETURN Internet.Write(nex^.trn(bsdSocket).socket, request);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END writer;

PROCEDURE readbufer(VAR nex: Client; VAR buf: ARRAY OF CHAR; VAR i: LONGINT): BOOLEAN;
BEGIN
  IF nex^.trn IS bsdSocket THEN
    i := 0;
    IF Internet.ReadBuf(nex^.trn(bsdSocket).socket, buf, i) THEN
      RETURN TRUE;
    ELSE
      i := 0;
      RETURN FALSE;
    END;
  ELSE
    Out.String("nex is not initialized with bsdSocket"); Out.Ln;
    RETURN FALSE;
  END;
END readbufer;

PROCEDURE reader(VAR nex: Client; VAR buffer: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF nex^.trn IS bsdSocket THEN
    RETURN Internet.Read(nex^.trn(bsdSocket).socket, buffer);
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END reader;

PROCEDURE buildRequest*(nex: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  len: INTEGER;
BEGIN
  len := Strings.Length(nex^.host^) + Strings.Length(nex^.path^) + 8; (* SP and EOL *)
  NEW(req, len);
  Strings.Append(nex^.path^, req^);
  Strings.Append(nex^.eol, req^);

  RETURN req;
END buildRequest;

PROCEDURE zeroBuf(VAR str: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0;
  REPEAT
  str[i] := 0X;
  INC(i);
  UNTIL i = LEN(str)
END zeroBuf;

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

PROCEDURE get*(nex: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  buf: ARRAY 4096 OF CHAR;
  i, j, k, totalBytes: LONGINT;
  b: BOOLEAN;
  saveFilename: ARRAY 256 OF CHAR;
  tmp: POINTER TO ARRAY OF CHAR;
  oldSize: LONGINT;
  file: Files.File;
  r: Files.Rider;
BEGIN
  nex^.clearState(nex);
  totalBytes := 0;

  IF (nex^.path # NIL) & (nex^.path^[0] # 0X) THEN
    COPY(nex^.path^, saveFilename);
    IF saveFilename[0] = '/' THEN
      i := 0;
      WHILE saveFilename[i+1] # 0X DO
        saveFilename[i] := saveFilename[i+1];
        INC(i);
      END;
      saveFilename[i] := 0X;
    END;
  ELSE
    COPY("nex_download.gmi", saveFilename);
  END;

  Out.String("Will save as: "); Out.String(saveFilename); Out.Ln;
  nex^.connectionFlag := nex.Connect(nex);
  IF ~nex^.connectionFlag THEN
    Out.String("Connection failed"); Out.Ln;
    HALT(5);
  END;

  req := buildRequest(nex);
  b := writer(nex, req^);

  IF b THEN
    nex^.dyno := dynomaker(nex);
    k := 0;
    Out.String("Downloading...");
    REPEAT
      i := 0; 
      b := Internet.ReadBuf(nex^.trn(bsdSocket).socket, buf, i);

      IF b & (i > 0) THEN
        nex^.dyno^.size := totalBytes + i;
        IF nex^.dyno^.content = NIL THEN
          NEW(nex^.dyno^.content, i);
          FOR j := 0 TO i - 1 DO
            nex^.dyno^.content^[j] := buf[j];
          END;
        ELSE
          oldSize := totalBytes;
          NEW(tmp, oldSize);
          FOR j := 0 TO oldSize - 1 DO
            tmp^[j] := nex^.dyno^.content^[j];
          END;
          NEW(nex^.dyno^.content, oldSize + i);
          FOR j := 0 TO oldSize - 1 DO
            nex^.dyno^.content^[j] := tmp^[j];
          END;
          FOR j := 0 TO i - 1 DO
            nex^.dyno^.content^[oldSize + j] := buf[j];
          END;
        END;

        totalBytes := totalBytes + i;
        Out.Char('.');
      END;

      INC(k);
    UNTIL ~b OR (i = 0);

    Out.Ln;
    Out.String("Total bytes downloaded: "); Out.Int(totalBytes, 0); Out.Ln;
    NEW(nex^.rspnBody, totalBytes + 1);
    FOR i := 0 TO totalBytes - 1 DO
      nex^.rspnBody^[i] := nex^.dyno^.content^[i];
    END;
    nex^.rspnBody^[totalBytes] := 0X;
    file := Files.New(saveFilename);
    IF file # NIL THEN
      Files.Set(r, file, 0);
      FOR i := 0 TO totalBytes - 1 DO
        Files.Write(r, nex^.dyno^.content^[i]);
      END;
      Files.Register(file);
      Files.Close(file);
      Out.String("File saved: "); Out.String(saveFilename); Out.Ln;
    ELSE
      Out.String("Failed to create file"); Out.Ln;
    END;
  ELSE
    Out.String("Failed to send request"); Out.Ln;
    HALT(5);
  END;

  nex.Disconnect(nex);
  RETURN nex^.rspnBody;
END get;

PROCEDURE Create*(host, port, path: ARRAY OF CHAR): Client;
VAR
  nex: Client;
  socket: bsdSocket;
BEGIN
  NEW(nex);
  nex^.eol[0] := 0DX; nex^.eol[1] := 0AX; nex^.null[0] := 0X;
  strUtils.string2pstring(host, nex^.host);
  strUtils.string2pstring(port, nex^.port);
  strUtils.string2pstring(path, nex^.path);
  nex^.contentLength := 0;
  nex^.Create := Create;
  nex^.Get := get;
  nex^.clearState := clearState;
  NEW(socket);
  nex^.trn := socket;
  nex^.Connect := connector;
  nex^.Disconnect := disconnector;
  nex^.Write := writer;
  nex^.Read := reader;
  nex^.Dynomaker := dynomaker;
  nex^.Save := saver;
  RETURN nex;
END Create;

END NEX.
