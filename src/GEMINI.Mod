MODULE GEMINI;

IMPORT IntStr := oocIntStr, Strings, Files, Out, Internet, strTypes, strUtils, dynamicarray, http, mbedtls, SYSTEM;

CONST
  defName = "index.gmi";
  protocol = "gemini://";

TYPE
  transport* = POINTER TO transportDesc;
  transportDesc* = RECORD END;

  bsdSocket* = POINTER TO bsdSocketDesc;
  bsdSocketDesc = RECORD(transportDesc)
    socket : Internet.Socket
  END;

   TLSSocket = POINTER TO TLSSocketDesc;
   TLSSocketDesc = RECORD(transportDesc)
     netContext* : ARRAY 512 OF CHAR;    (* 4 bytes are enough *)
     sslContext* : ARRAY 512 OF CHAR;   (* 472 bytes *)
     sslConf*    : ARRAY 512 OF CHAR;   (* 400 bytes *)
   END;



  Client* = POINTER TO ClientDesc;

  ClientDesc* = RECORD
    entropy*  : ARRAY 40000 OF CHAR; (* 1080 on x86_64, 37000 on armhl *)
    ctrDrbg*  : ARRAY 512 OF CHAR;   (* 392 bytes *)
    cacert*   : ARRAY 1024 OF CHAR;  (* 616 bytes *)
    crtpath*   : ARRAY 256 OF CHAR;
    pers*     : ARRAY 128 OF CHAR;

  setCertPath*  : PROCEDURE (VAR h: Client; path: ARRAY OF CHAR);
   setPers*      : PROCEDURE (VAR h: Client; pers: ARRAY OF CHAR);
      Init*      : PROCEDURE (VAR h: Client);


    host*, port*, path*: strTypes.pstring;
    connectionFlag*: BOOLEAN;
    trn*: transport;
    rspnBody*: strTypes.pstring;
    header-: strTypes.pstring;
    mimetype-: strTypes.pstring;
    statusCode: LONGINT;
    statusRead-: ARRAY 64 OF CHAR;
    rspnFirstLine*: strTypes.pstring;
    contentLength*: LONGINT;
    eol*: ARRAY 2 OF CHAR;
    null*: ARRAY 1 OF CHAR;
    dyno: dynamicarray.dynamicarray;
    Create*: PROCEDURE(host, port, path: ARRAY OF CHAR): Client;
    Get*: PROCEDURE(gemini: Client): strTypes.pstring;
    clearState*: PROCEDURE(VAR gemini: Client);
    Connect*: PROCEDURE(VAR gemini: Client): BOOLEAN;
    Disconnect*: PROCEDURE(VAR gemini: Client);
    Write*: PROCEDURE(VAR gemini: Client; request: ARRAY OF CHAR): BOOLEAN;
    Read*: PROCEDURE(VAR gemini: Client; VAR buf: ARRAY OF CHAR; toRead: LONGINT): BOOLEAN;
    Dynomaker: PROCEDURE(VAR gemini: Client): dynamicarray.dynamicarray;
    Save*: PROCEDURE(VAR gemini: Client; name: ARRAY OF CHAR);
(*TODO use reader in create*)

END;

PROCEDURE init(VAR gemini: Client);
BEGIN
  Out.String("entered init"); Out.Ln;
  IF gemini^.trn IS TLSSocket THEN
    mbedtls.init(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext,
                gemini^.trn(TLSSocket).sslConf, gemini^.entropy, gemini^.ctrDrbg,
                gemini^.cacert, gemini^.pers, gemini^.crtpath);

    (* Disable certificate verification *)
    mbedtls.setAuthModeNone(gemini^.trn(TLSSocket).sslConf);
    Out.String("Certificate verification disabled"); Out.Ln;
  END;
  Out.String("left init"); Out.Ln;
END init;

PROCEDURE setcertpath(VAR gemini: Client; path: ARRAY OF CHAR);
BEGIN
  COPY(path, gemini^.crtpath);
END setcertpath;

(* Personalization data (Device specific identifiers) *)
PROCEDURE setpers(VAR gemini: Client; str: ARRAY OF CHAR);
BEGIN
    Out.String("test"); Out.Ln;
  COPY(str, gemini^.pers)
END setpers;

PROCEDURE connector(VAR gemini: Client):BOOLEAN;
VAR i: LONGINT;
BEGIN
  gemini.connectionFlag := FALSE;
  IF gemini^.trn IS TLSSocket THEN
    Out.String("Connecting to "); Out.String(gemini^.host^);
    Out.String(":"); Out.String(gemini^.port^); Out.Ln;
    (* We already disabled certificate verification in init procedure *)
    i := mbedtls.connect(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext,
                       gemini^.trn(TLSSocket).sslConf, gemini(Client)^.entropy,
                       gemini(Client)^.ctrDrbg, gemini(Client)^.cacert,
                       gemini^.host^, gemini^.port^);

    IF i = 0 THEN
      gemini^.connectionFlag := TRUE;
      Out.String("Connection established successfully"); Out.Ln;
    ELSE
      gemini^.connectionFlag := FALSE;
      Out.String("Connection failed with code: "); Out.Int(i,0); Out.Ln;
      IF i = -9984 THEN
        Out.String("SSL handshake failed even with verification disabled"); Out.Ln
      ELSIF i = -19968 THEN
        Out.String("Network connection failed"); Out.Ln
      ELSE
        Out.String("Unknown TLS error"); Out.Ln
      END;
    END;
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
  RETURN gemini^.connectionFlag
END connector;

PROCEDURE disconnector(VAR gemini: Client);
VAR
  i: LONGINT;
BEGIN
  IF gemini IS Client THEN
    i := mbedtls.disconnect(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext, gemini^.trn(TLSSocket).sslConf, gemini(Client)^.entropy, gemini(Client)^.ctrDrbg);
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
END disconnector;

PROCEDURE reader*(VAR gemini: Client; VAR buf: ARRAY OF CHAR; toRead: LONGINT): BOOLEAN;
VAR
  len, r, i: LONGINT;
BEGIN
  r := -1;
  IF gemini^.trn IS TLSSocket THEN
    IF toRead = -1 THEN
      len := LEN(buf)-1  (* Leave room for null terminator *)
    ELSE
      len := toRead
    END;

    r := mbedtls.read(gemini^.trn(TLSSocket).sslContext, buf, len);
    Out.String("mbedtls.read returned: "); Out.Int(r, 0); Out.Ln;

    (* Ensure null termination if we read any data *)
    IF r > 0 THEN
      IF r < LEN(buf) THEN
        buf[r] := 0X;  (* Explicitly add null terminator *)
      END;
    END;
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;

  RETURN (r > 0)
END reader;

PROCEDURE writer(VAR gemini: Client; buf: ARRAY OF CHAR):BOOLEAN;
VAR
  len: LONGINT; r: LONGINT;
BEGIN
  r := -1;
  IF gemini^.trn IS TLSSocket THEN
    Out.String("gemini client is initialized with tls socket"); Out.Ln;
    len := LEN(buf);
    Out.String("buf last char is "); Out.Int(ORD(buf[len-1]), 0); Out.Ln;
    r := mbedtls.write(gemini^.trn(TLSSocket).sslContext, buf, len);
    Out.String("the value of mbedtls write: "); Out.Int(r, 0); Out.Ln;
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
  RETURN r > 0;
END writer;

PROCEDURE readBuf(VAR gemini: Client; VAR buf: ARRAY OF CHAR; VAR haveRead: LONGINT): BOOLEAN;
VAR
  r: LONGINT;
BEGIN
  gemini^.connectionFlag := FALSE;
  IF gemini^.trn IS TLSSocket THEN
    (* Reset haveRead to 0 to ensure we count correctly *)
    haveRead := 0;
    r := mbedtls.readBuf(gemini^.trn(TLSSocket).netContext, gemini^.trn(TLSSocket).sslContext, buf, haveRead);
    Out.String("readBuf result: "); Out.Int(r, 0);
    Out.String(", bytes read: "); Out.Int(haveRead, 0); Out.Ln;
    IF r <= 0 THEN
      gemini^.connectionFlag := FALSE;
      haveRead := 0;
    ELSE
      gemini^.connectionFlag := TRUE;
    END;
  ELSE
    Out.String("gemini client is not initialized with tls socket"); Out.Ln;
    HALT(5);
  END;
  RETURN gemini^.connectionFlag & (haveRead > 0);
END readBuf;

PROCEDURE clearState*(VAR gemini: Client);
BEGIN
  gemini^.mimetype := NIL;
  gemini^.rspnBody := NIL;
  gemini^.header := NIL;
  gemini^.rspnFirstLine := NIL;
  gemini^.contentLength := 0;
END clearState;

PROCEDURE dynomaker(VAR gemini: Client): dynamicarray.dynamicarray;
BEGIN
RETURN dynamicarray.Create();
END dynomaker;

PROCEDURE saver(VAR gemini: Client; name: ARRAY OF CHAR);
BEGIN
  IF (gemini^.dyno = NIL) OR (gemini^.dyno^.size <= 0) THEN
    Out.String("No data to save or already saved"); Out.Ln;
    RETURN;
  END;
  dynamicarray.writetofile(gemini^.dyno, name);
  gemini^.dyno^.size := 0;  (* Mark as saved *)
END saver;

PROCEDURE buildRequest*(gemini: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  len: INTEGER;
BEGIN
  (* Format: "gemini://host/path<CR><LF>" *)
  len := Strings.Length(protocol) + Strings.Length(gemini^.host^) + Strings.Length(gemini^.path^) + 3;
  NEW(req, len);
  COPY(protocol, req^);
  Strings.Append(gemini^.host^, req^);
  Strings.Append(gemini^.path^, req^);
  req^[len-3] := 0DX;
  req^[len-2] := 0AX;
  req^[len-1] := 0X;
  Out.String("Built Gemini request: "); Out.String(req^); Out.Ln;
  RETURN req;
END buildRequest;

PROCEDURE getMimetype(VAR gemini: Client; VAR str: ARRAY OF CHAR; startPos: LONGINT);
VAR
  i, j, mimeLen: LONGINT;
  mim: ARRAY 64 OF CHAR; (* Increased size *)
BEGIN
  Out.String("entered getMimetype"); Out.Ln;

  (* First, find the length of the MIME type string *)
  i := startPos;
  mimeLen := 0;
  WHILE (i < LEN(str)) & (str[i] # 0X) & (str[i] # ';') DO
    INC(i);
    INC(mimeLen);
  END;

  (* Now extract the MIME type *)
  NEW(gemini.mimetype, mimeLen + 1); (* +1 for null terminator *)

  FOR j := 0 TO mimeLen - 1 DO
    IF startPos + j < LEN(str) THEN
      gemini.mimetype^[j] := str[startPos + j];
    END;
  END;
  gemini.mimetype^[mimeLen] := 0X;

  Out.String("MIME type: "); Out.String(gemini.mimetype^); Out.Ln;
END getMimetype;

PROCEDURE parseHeader(VAR gemini: Client; VAR str: ARRAY OF CHAR);
VAR
  i, statuscodeint: LONGINT;
  res: IntStr.ConvResults;
  statuscode: ARRAY 4 OF CHAR;
BEGIN
  Out.String("header is: '"); Out.String(str); Out.String("'"); Out.Ln;
  i := 0;
  res := 0;
  statuscode := "";

  REPEAT
    IF i < LEN(statuscode) THEN
      statuscode[i] := str[i];
    END;
    INC(i);
  UNTIL (i >= LEN(str)) OR (str[i] = ' ');

  IF i < LEN(statuscode) THEN
    statuscode[i] := 0X;
  ELSE
    statuscode[LEN(statuscode)-1] := 0X;
  END;

  IntStr.StrToInt(statuscode, statuscodeint, res);
  IF res # IntStr.strAllRight THEN
    Out.String("status code: "); Out.String(statuscode);
    Out.String(" is invalid and cannot be converted to integer.");
    Out.Ln;
    HALT(1);
  END;

  IF (statuscodeint < 10) OR (statuscodeint > 69) THEN
    Out.String("invalid status code, it should be between ten and sixty nine"); Out.Ln; HALT(6);
  END;

  Out.String("assigning the status code to the client"); Out.Ln;

  IF (statuscodeint >= 10) & (statuscodeint <= 19) THEN
    gemini^.statusCode := 10;
    gemini^.statusRead := "Input expected";
  ELSIF (statuscodeint >= 20) & (statuscodeint < 30) THEN
    gemini^.statusRead := "Success";
    gemini^.statusCode := 20;
    IF (i < LEN(str)) & (str[i] = ' ') THEN
      INC(i); (* Skip the space after status code *)
      getMimetype(gemini, str, i);
    END;
  ELSIF (statuscodeint >= 30) & (statuscodeint < 40) THEN
    gemini^.statusCode := 30;
    gemini^.statusRead := "Redirection";
  ELSIF (statuscodeint >= 40) & (statuscodeint < 50) THEN
    gemini^.statusCode := 40;
    gemini^.statusRead := "Temporary failure";
  ELSIF (statuscodeint >= 50) & (statuscodeint < 60) THEN
    gemini^.statusCode := 50;
    gemini^.statusRead := "Permanent failure";
  ELSIF (statuscodeint >= 60) & (statuscodeint <= 69) THEN
    gemini^.statusCode := 60;
    gemini^.statusRead := "Client certificates";
  ELSE
    gemini.statusCode := statuscodeint;
  END;

  Out.String("assigned the status read to the client: "); Out.String(gemini^.statusRead); Out.Ln;
END parseHeader;

PROCEDURE zeroBuf(VAR str: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0;
  REPEAT
  str[i] := 0X;
  INC(i);
  UNTIL i = LEN(str)
END zeroBuf;

PROCEDURE readTillCRLF(gemini: Client);
VAR
  buf: ARRAY 2 OF CHAR;
  hdr: ARRAY 256 OF CHAR;
  b: BOOLEAN;
  i: INTEGER;
BEGIN
  COPY("", hdr); i := 0;
  REPEAT
    b := gemini.Read(gemini, buf, 1);
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
  b := gemini.Read(gemini, buf, 1);
  IF b THEN
    IF buf[0] # 0AX THEN
      Out.String("0AX expected, got: "); Out.Int(ORD(buf[0]), 0);
      Out.Ln; HALT(1);
    END;
  ELSE
    Out.String("failed to read"); Out.Ln; HALT(3)
  END;
  NEW(gemini^.header, Strings.Length(hdr)+1);
  COPY(hdr, gemini^.header^);
  parseHeader(gemini, gemini^.header^);
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

PROCEDURE ensureFileExtension(VAR filename: ARRAY OF CHAR; extension: ARRAY OF CHAR);
VAR
  i, j, len, dotPos: LONGINT;
  hasExt: BOOLEAN;
BEGIN
  len := 0;
  WHILE (len < LEN(filename)) & (filename[len] # 0X) DO
    INC(len);
  END;

  dotPos := -1;
  FOR i := 0 TO len-1 DO
    IF filename[i] = '.' THEN
      dotPos := i;
    END;
  END;

  IF dotPos >= 0 THEN
    hasExt := TRUE;
    j := 0;
    FOR i := dotPos TO len-1 DO
      IF j < LEN(extension) THEN
        IF extension[j] # filename[i] THEN
          hasExt := FALSE;
        END;
        INC(j);
      END;
    END;

    IF hasExt THEN
      RETURN;
    END;
  END;

  IF len + Strings.Length(extension) < LEN(filename) THEN
    Strings.Append(extension, filename);
    Out.String("Added extension: "); Out.String(extension); Out.Ln;
  ELSE
    Out.String("Warning: Not enough space to add file extension"); Out.Ln;
  END;
END ensureFileExtension;

PROCEDURE copyFile(source, dest: ARRAY OF CHAR);
VAR
  srcFile, destFile: Files.File;
  r1, r2: Files.Rider;
  ch: CHAR;
BEGIN
  srcFile := Files.Old(source);
  IF srcFile = NIL THEN
    Out.String("Error: Source file not found: "); Out.String(source); Out.Ln;
    RETURN;
  END;

  destFile := Files.New(dest);
  IF destFile = NIL THEN
    Out.String("Error: Could not create destination file: "); Out.String(dest); Out.Ln;
    RETURN;
  END;

  Files.Set(r1, srcFile, 0);
  Files.Set(r2, destFile, 0);

  WHILE ~r1.eof DO
    Files.Read(r1, ch);
    IF ~r1.eof THEN
      Files.Write(r2, ch);
    END;
  END;

  Files.Register(destFile);
  Files.Close(destFile);

  Out.String("Created compatibility copy as: "); Out.String(dest); Out.Ln;
END copyFile;

PROCEDURE get*(gemini: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  readBuf: ARRAY 1024 OF CHAR;
  i, j, totalBytes, readLen, r: LONGINT;
  b: BOOLEAN;
  saveFilename: ARRAY 256 OF CHAR;
  file: Files.File;
  rider: Files.Rider;
  readAttempts: LONGINT;
  consecutiveEmptyReads: LONGINT;
  fileExtension: ARRAY 16 OF CHAR;
  path: ARRAY 512 OF CHAR;
BEGIN
  gemini^.clearState(gemini);
  totalBytes := 0;
  consecutiveEmptyReads := 0;
  COPY(gemini^.path^, path);
  extractFilename(path, saveFilename);

  IF (gemini^.mimetype # NIL) THEN
    (* Will be set after getting header, we'll update filename later *)
    Out.String("MIME type will be checked after header is received"); Out.Ln;
  END;

  Out.String("Will save as: "); Out.String(saveFilename); Out.Ln;

  (* Connect to server *)
  gemini^.connectionFlag := gemini.Connect(gemini);
  IF ~gemini^.connectionFlag THEN
    Out.String("Connection failed"); Out.Ln;
    HALT(5);
  END;

  req := buildRequest(gemini);
  b := gemini.Write(gemini, req^);

  IF b THEN
    readTillCRLF(gemini);
    Out.String("Header received, status: "); Out.Int(gemini^.statusCode, 0); Out.Ln;

    IF (gemini^.statusCode = 20) & (gemini^.mimetype # NIL) THEN
      IF Strings.Pos("application/pdf", gemini^.mimetype^, 0) >= 0 THEN
        ensureFileExtension(saveFilename, ".pdf");
      ELSIF Strings.Pos("text/gemini", gemini^.mimetype^, 0) >= 0 THEN
        ensureFileExtension(saveFilename, ".gmi");
      ELSIF Strings.Pos("text/plain", gemini^.mimetype^, 0) >= 0 THEN
        ensureFileExtension(saveFilename, ".txt");
      ELSIF Strings.Pos("text/html", gemini^.mimetype^, 0) >= 0 THEN
        ensureFileExtension(saveFilename, ".html");
      ELSIF Strings.Pos("image/jpeg", gemini^.mimetype^, 0) >= 0 THEN
        ensureFileExtension(saveFilename, ".jpg");
      ELSIF Strings.Pos("image/png", gemini^.mimetype^, 0) >= 0 THEN
        ensureFileExtension(saveFilename, ".png");
      END;

      Out.String("Final filename with proper extension: "); Out.String(saveFilename); Out.Ln;
    END;

    IF (gemini^.statusCode = 20) THEN
      (* For binary data, let's open the file immediately and write as we go *)
      Out.String("Downloading content..."); Out.Ln;

      (* Open the file for writing immediately *)
      file := Files.New(saveFilename);
      IF file = NIL THEN
        Out.String("Failed to create file"); Out.Ln;
        HALT(7);
      END;

      Files.Set(rider, file, 0);

      (* Direct read-and-write loop for better binary data handling *)
      readAttempts := 0;
      REPEAT
        (* Clear the read buffer *)
        FOR i := 0 TO LEN(readBuf) - 1 DO
          readBuf[i] := 0X;
        END;

        (* Read directly using mbedtls *)
        r := mbedtls.read(gemini^.trn(TLSSocket).sslContext, readBuf, LEN(readBuf) - 1);
        Out.String("mbedtls.read returned: "); Out.Int(r, 0); Out.Ln;

        (* Use the return value for bytes read *)
        readLen := r;

        IF readLen > 0 THEN
          (* Reset empty read counter *)
          consecutiveEmptyReads := 0;

          Out.String("Read "); Out.Int(readLen, 0); Out.String(" bytes."); Out.Ln;

          (* Write directly to file - byte by byte to ensure binary integrity *)
          FOR i := 0 TO readLen - 1 DO
            Files.Write(rider, readBuf[i]);
          END;

          (* Update total size *)
          totalBytes := totalBytes + readLen;
          Out.Char('.');
        ELSIF r = 0 THEN
          (* Zero bytes read could mean end of data or need to wait *)
          INC(consecutiveEmptyReads);
          Out.String("Empty read #"); Out.Int(consecutiveEmptyReads, 0); Out.Ln;
        ELSE
          (* Negative return means error or connection closed *)
          Out.String("Read error: "); Out.Int(r, 0); Out.Ln;
          (* Exit loop on error, but this might be normal end of connection *)
          IF consecutiveEmptyReads > 0 THEN
            (* If we've already had empty reads, this is probably normal termination *)
            Out.String("Normal connection termination detected"); Out.Ln;
          ELSE
            (* Otherwise it might be an actual error *)
            Out.String("Connection error detected"); Out.Ln;
          END;
          consecutiveEmptyReads := 5; (* Force exit *)
        END;

        INC(readAttempts);
      UNTIL (consecutiveEmptyReads >= 5) OR (readAttempts > 100000);

      Files.Register(file);
      Files.Close(file);
      Out.Ln;
      Out.String("Total bytes downloaded: "); Out.Int(totalBytes, 0); Out.Ln;
      Out.String("File saved: "); Out.String(saveFilename); Out.Ln;
      NEW(gemini^.rspnBody, 1);
      gemini^.rspnBody^[0] := 0X;
      (* Also copy to defaultname.gmi for backward compatibility *)
      IF saveFilename # defName THEN
        copyFile(saveFilename, defName);
      END;
      (* Mark as saved to prevent duplicate saves *)
      gemini^.dyno := dynamicarray.Create();
      gemini^.dyno^.size := 0;
    ELSE
      Out.String("Status code indicates no content available."); Out.Ln;
    END;
  ELSE
    Out.String("Failed to send request"); Out.Ln;
    HALT(5);
  END;

  gemini.Disconnect(gemini);
  RETURN gemini^.rspnBody;
END get;

PROCEDURE Create*(host, port, path: ARRAY OF CHAR): Client;
VAR
  gemini: Client;
  socket: TLSSocket;
BEGIN
  NEW(gemini);
  gemini^.eol[0] := 0DX; gemini^.eol[1] := 0AX; gemini^.null[0] := 0X;
  strUtils.string2pstring(host, gemini^.host);
  strUtils.string2pstring(port, gemini^.port);
  strUtils.string2pstring(path, gemini^.path);
  gemini^.contentLength := 0;
  gemini^.Get := get;
  gemini^.Create := Create;
  gemini^.clearState := clearState;
  NEW(socket);
  gemini^.trn := socket;
  gemini.Connect := connector;
  gemini.Disconnect := disconnector;
  (*TODO fix this*)
  gemini.Read := reader;
  gemini.Write := writer;
  gemini^.Dynomaker := dynomaker;
  gemini^.Save := saver;
  gemini.setCertPath := setcertpath;
  gemini.setPers     := setpers;
  gemini.setCertPath(gemini, "/etc/ssl/certs/ca-certificates.crt");
  gemini.setPers(gemini, "oberon_mbedtls_client");
  gemini.Init := init;

  RETURN gemini;
END Create;

END GEMINI.
