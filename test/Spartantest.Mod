MODULE Spartantest;
IMPORT SPARTAN, strTypes, Out, dynamicarray;

PROCEDURE testClient1;
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
a := s.Save(s, "specifications.txt");
END testClient1;

PROCEDURE testClient2;
VAR 
s: SPARTAN.Client;
answer: strTypes.pstring;
a: dynamicarray.dynamicarray;

BEGIN
Out.String("running spartan test");Out.Ln;
s := SPARTAN.Create("spartan.mozz.us", "300", "/spartan_client.py");
Out.String("created connection");Out.Ln;
answer := s.Get(s);
Out.String("response: "); Out.String(answer^);
a := s.Save(s, "spartan_client.py");
END testClient2;

PROCEDURE testClient3;
VAR 
s: SPARTAN.Client;
answer: strTypes.pstring;
a: dynamicarray.dynamicarray;

BEGIN
Out.String("running spartan test");Out.Ln;
s := SPARTAN.Create("spartan.mozz.us", "300", "/design-goals.gmi");
Out.String("created connection");Out.Ln;
answer := s.Get(s);
Out.String("response: "); Out.String(answer^);
a := s.Save(s, "design-goals.gmi");
END testClient3;



BEGIN

testClient1;
(*testClient2;
testClient3;
*)
END Spartantest.
