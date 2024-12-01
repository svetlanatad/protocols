MODULE Spartantest;
IMPORT SPARTAN, strTypes, Out, dynamicarray;

PROCEDURE testClient;
VAR 
s: SPARTAN.Client;
answer: strTypes.pstring;
a: dynamicarray.dynamicarray;

BEGIN
Out.String("running spartan test");Out.Ln;
s := SPARTAN.Create("spartan.mozz.us", "300", "/specification.gmi");
Out.String("created connection");Out.Ln;
answer := s.Get(s);
Out.String("response: "); Out.String(answer^);
a := s.Save(s, "itworked.txt");
END testClient;

BEGIN

testClient;

END Spartantest.
