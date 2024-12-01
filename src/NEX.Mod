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
    Save*: PROCEDURE(VAR nex: Client; name: ARRAY OF CHAR): dynamicarray.dynamicarray;
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

PROCEDURE saver(VAR nex: Client; name: ARRAY OF CHAR): dynamicarray.dynamicarray;
BEGIN
RETURN dynamicarray.writetofile(nex^.dyno, name);
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
  (*b := Internet.Write(nex^.trn(bsdSocket).socket, req^);*)
  ELSE
    Out.String("Spartan client is not initialized with bsd socket"); Out.Ln;
    RETURN FALSE;
  END;
END writer;

PROCEDURE readbufer(VAR nex: Client; VAR buf: ARRAY OF CHAR; VAR i: LONGINT): BOOLEAN;
BEGIN
IF nex^.trn IS bsdSocket THEN 
   RETURN Internet.ReadBuf(nex^.trn(bsdSocket).socket, buf, i); 
ELSE 
Out.String("nex is not inintialized with bsdSocket");Out.Ln;
RETURN FALSE;
END
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
  (* Allocate request size based on host and path lengths *)
  len := Strings.Length(nex^.host^) + Strings.Length(nex^.path^) + 8; (* SP and EOL *)
  NEW(req, len);

  (* Build the request line *)
 (* Strings.Append(nex^.host^, req^);*)
  (*COPY(nex^.host^, req^);*)
  Strings.Append(nex^.path^, req^);
  (*Strings.Append(" ", req^);*)
  (*                ^ ask inky: I keep changing this and the next line to Append " 0", req^ and it gives either the nex protocol or # the nex protocol*)
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



PROCEDURE get*(nex: Client): strTypes.pstring;
VAR
  req: strTypes.pstring;
  buf: ARRAY 16 OF CHAR;
  (*ok so apparentl this k logic works iff reading chunk size is 16*)
  i, k: LONGINT;
  b: BOOLEAN;
  responseArr: dynamicarray.dynamicarray; 
BEGIN
  nex^.clearState(nex);

  nex^.connectionFlag := nex.Connect(nex);
  IF ~nex^.connectionFlag THEN
    Out.String("Connection failed"); Out.Ln;
    HALT(5);
  END;

  req := buildRequest(nex);
  b := writer(nex, req^);

  IF b THEN
    nex^.dyno := dynomaker(nex);
    responseArr := dynamicarray.Create();
    i := 0; k := 0;

    REPEAT
      zeroBuf(buf);
      (*b := Internet.ReadBuf(nex^.trn(bsdSocket).socket, buf, i);*)
         (*ask inky: when i implement it with oop with the line of code next, it incorrectly reads the request*)
       b := readbufer(nex, buf, i);
                (* ^ think later this is too weird*)
      
      Out.String("-------------"); Out.Ln;
      Out.String(buf); Out.Ln;
      Out.String("-------------"); Out.Ln;
      
      IF k = 0 THEN
         responseArr.appender(responseArr, "");
         nex^.dyno.appender(nex^.dyno, "");
         Out.String("content of the respons arr during first iter"); Out.String(responseArr.content^); Out.Ln;

        Out.String("Tried to skip appending"); Out.Ln;
      ELSE
        responseArr.appender(responseArr, buf);
        nex^.dyno.appender(nex^.dyno, buf);
      END;
      Out.String("Response array contents so far:"); Out.Ln;
      Out.String("-------------------------------------------------"); Out.Ln;
      Out.String(responseArr^.content^); Out.Ln;
      Out.String(nex^.dyno^.content^); Out.Ln;
      Out.String("-------------------------------------------------"); Out.Ln;

      INC(k);
    UNTIL ~b OR (i = 0);
    NEW(nex^.rspnBody, LEN(nex^.dyno^.content^)); 
    (*NEW(nex^.rspnBody, LEN(responseArr^.content^));*)
    COPY(nex^.dyno^.content^, nex^.rspnBody^);
    (*COPY(responseArr^.content^, nex^.rspnBody^);*)
  ELSE
    Out.String("Failed to send request"); Out.Ln;
    HALT(5);
  END;

  nex.Disconnect(nex);
  (*nex^.dyno := saver(nex, "H.txt");*)
  (*dynamicarray.writetofile(responseArr, "HULLO.txt");*)
  RETURN nex^.rspnBody;
END get;




PROCEDURE Create*(host, port, path: ARRAY OF CHAR): Client;
VAR
  nex: Client;
  socket: bsdSocket;
BEGIN
  NEW(nex);
  nex^.eol[0] := 0DX; nex^.eol[1] := 0AX; nex^.null[0] := 0X;

  (* Initialize fields *)
  strUtils.string2pstring(host, nex^.host);
  strUtils.string2pstring(port, nex^.port);
  strUtils.string2pstring(path, nex^.path);

  (* Set default values *)
  nex^.contentLength := 0;

  (* Assign methods *)
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
