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
    Save*: PROCEDURE(VAR spartan: Client; name: ARRAY OF CHAR): dynamicarray.dynamicarray;
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

PROCEDURE saver(VAR spartan: Client; name: ARRAY OF CHAR): dynamicarray.dynamicarray;
BEGIN
RETURN dynamicarray.writetofile(spartan^.dyno, name);
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
  (*b := Internet.Write(spartan^.trn(bsdSocket).socket, req^);*)
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END writer;

PROCEDURE readbuffer(VAR spartan: Client; VAR buf: ARRAY OF CHAR; VAR i: LONGINT): BOOLEAN;
BEGIN
IF spartan^.trn IS bsdSocket THEN 
   RETURN Internet.ReadBuf(spartan^.trn(bsdSocket).socket, buf, i); 
ELSE 
Out.String("spartan is not inintialized with bsdSocket");Out.Ln;
RETURN FALSE;
END
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
  (* Allocate request size based on host and path lengths *)
  len := Strings.Length(spartan^.host^) + Strings.Length(spartan^.path^) + 10; (* SP and EOL *)
  NEW(req, len);

  (* Build the request line *)
  Strings.Append(spartan^.host^, req^);
  (*COPY(spartan^.host^, req^);*)
  Strings.Append(" ", req^);
  Strings.Append(spartan^.path^, req^);
  (*Strings.Append(" ", req^);*)
  (*                ^ ask inky: I keep changing this and the next line to Append " 0", req^ and it gives either the spartan protocol or # the spartan protocol*)
  Strings.Append(" 0", req^); (* Placeholder for content-length in Spartan *)
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
  REPEAT
  str[i] := 0X;
  INC(i);
  UNTIL i = LEN(str)
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

PROCEDURE get*(spartan: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  buf: ARRAY 16 OF CHAR;
  (*ok so apparentl this k logic works iff reading chunk size is 16*)
  (*so now it works with 14 bytes but doesnt read # in 16 bytes*)
  i, k: LONGINT;
  b: BOOLEAN;
  responseArr: dynamicarray.dynamicarray; 
  (*header: dynamicarray.dynamicarray;*)
BEGIN
  spartan^.clearState(spartan);

  spartan^.connectionFlag := spartan.Connect(spartan);
  IF ~spartan^.connectionFlag THEN
    Out.String("Connection failed"); Out.Ln;
    HALT(5);
  END;

  req := buildRequest(spartan);
  b := writer(spartan, req^);

  IF b THEN
    spartan^.dyno := dynomaker(spartan);
    (*responseArr := dynamicarray.Create();*)
    i := 0; k := 0;
    readTillCRLF(spartan);
    REPEAT
      zeroBuf(buf);
      (*b := Internet.ReadBuf(spartan^.trn(bsdSocket).socket, buf, i);*)
         (*ask inky: when i implement it with oop with the line of code next, it incorrectly reads the request*)
      b := readbuffer(spartan, buf, i);
                (* ^ think later this is too weird*)
      IF b THEN 
        Out.String("-------------"); Out.Ln;
        Out.String(buf); Out.Ln;
        Out.String("-------------"); Out.Ln;
     
      (* 
      IF k = 0 THEN
         (*idea
          create a dyn array here 
          append the buf here 
          store it to a global field of spartan
          write toa seperate file to read
         *)
         (*spartan^.header := dynomaker(spartan);*)
	 (*spartan^.header.appender(spartan^.header, buf);*)
	 header.appender(header, buf);
         NEW(spartan^.headerbody, LEN(buf));
	 COPY(header^.content^, spartan^.headerbody^);
         (*parseHeader(spartan, spartan^.headerbody^);*)
         responseArr.appender(responseArr, "");
         spartan^.dyno.appender(spartan^.dyno, "");
         Out.String("content of the respons arr during first iter"); Out.String(responseArr.content^); Out.Ln;

        Out.String("Tried to skip appending"); Out.Ln;
      ELSE
      *)

      (*responseArr.appender(responseArr, buf);*)
       (* NEW(spartan^.dyno^.content, LEN(buf));*)
      spartan^.dyno.appender(spartan^.dyno, buf);
      (*END;*)
      Out.String("Response array contents so far:"); Out.Ln;
      Out.String("-------------------------------------------------"); Out.Ln;
     (* Out.String(responseArr^.content^); Out.Ln;*)
      Out.String(spartan^.dyno^.content^); Out.Ln;
      Out.String("-------------------------------------------------"); Out.Ln;
      ELSE 
        Out.String("couldnt connect"); Out.Ln;
      END;
    UNTIL ~b OR (i = 0);
    NEW(spartan^.rspnBody, LEN(spartan^.dyno^.content^)); 
    (*NEW(spartan^.rspnBody, LEN(responseArr^.content^));*)
    COPY(spartan^.dyno^.content^, spartan^.rspnBody^);
    (*COPY(responseArr^.content^, spartan^.rspnBody^);*)
  ELSE
    Out.String("Failed to send request"); Out.Ln;
    HALT(5);
  END;
  
  spartan.Disconnect(spartan);
  (*parseHeader(spartan, spartan^.headerbody^);*)
  (*Out.String("HEADER CONTENT##################################################################"); Out.String(header^.content^); Out.Ln;
  Out.String("HEADER CONTENT-----------------------------------------------------------------"); Out.String(spartan^.headerbody^); Out.Ln;
  Out.String("STATUS CODE #######################################################"); Out.Int(spartan^.statusCode, 0); Out.Ln;*)
  (*spartan^.dyno := saver(spartan, "H.txt");*)
  (*dynamicarray.writetofile(responseArr, "HULLO.txt");*)
  (*spartan^.header := saver(spartan, "header.txt");*) 
  RETURN spartan^.rspnBody;
END get;




PROCEDURE Create*(host, port, path: ARRAY OF CHAR): Client;
VAR
  spartan: Client;
  socket: bsdSocket;
BEGIN
  NEW(spartan);
  spartan^.eol[0] := 0DX; spartan^.eol[1] := 0AX; spartan^.null[0] := 0X;

  (* Initialize fields *)
  strUtils.string2pstring(host, spartan^.host);
  strUtils.string2pstring(port, spartan^.port);
  strUtils.string2pstring(path, spartan^.path);

  (* Set default values *)
  spartan^.contentLength := 0;

  (* Assign methods *)
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
