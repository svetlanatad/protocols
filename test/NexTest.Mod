MODULE NexTest;
IMPORT NEX, strTypes, Out, dynamicarray;

PROCEDURE testClient1;
VAR 
s: NEX.Client;
answer: strTypes.pstring;
a: dynamicarray.dynamicarray;

BEGIN
Out.String("running spartan test");Out.Ln;
s := NEX.Create("mozz.us", "1900", "/nex-protocol-notes.txt");
Out.String("created connection");Out.Ln;
answer := s.Get(s);
Out.String("response: "); Out.String(answer^);
a := s.Save(s, "nexoop.txt");
END testClient1;


BEGIN

testClient1;

END NexTest.
