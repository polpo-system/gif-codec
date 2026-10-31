MODULE GIFMemoryTest;  (** loksh GIFMemoryTest.Run, GIFMemoryTest.Fixtures gifsuite.list: GIF0 in memory (GIF0.DecodeBytes, EncodeBytes, ReadInfoBytes) *)

(* After the PictureMemoryTest of voc 4.0.6. Run: a picture made here encoded into memory and decoded again,
  the same bytes as through a rider, the pixel limit and the output limit, and broken or cut data refused.
  Fixtures: each picture of the list read with the byte-array entry points and with the rider ones, the
  same results and pixels. *)

IMPORT Files, Texts, out, GIF0;

VAR checks, failed: LONGINT; phase: ARRAY 256 OF CHAR;

PROCEDURE Check(value: BOOLEAN);
BEGIN
  INC(checks);
  IF ~value THEN INC(failed); out.String("FAIL "); out.String(phase); out.String(", check "); out.Int(checks, 0); out.Ln END
END Check;

PROCEDURE Equal(VAR a, b: ARRAY OF CHAR; length: LONGINT): BOOLEAN;
VAR i: LONGINT;
BEGIN
  IF (length < 0) OR (length > LEN(a)) OR (length > LEN(b)) THEN RETURN FALSE END;
  i := 0; WHILE i < length DO IF a[i] # b[i] THEN RETURN FALSE END; INC(i) END;
  RETURN TRUE
END Equal;

PROCEDURE Fill(VAR bytes: ARRAY OF CHAR);
VAR i, seed: LONGINT;
BEGIN
  seed := 1; i := 0;
  WHILE i < LEN(bytes) DO seed := (seed * 75 + 74) MOD 65537; bytes[i] := CHR(seed MOD 256); INC(i) END
END Fill;

PROCEDURE Load(VAR name: ARRAY OF CHAR; VAR data: Files.Bytes; VAR length: LONGINT): Files.File;
VAR f: Files.File; r: Files.Rider;
BEGIN
  f := Files.Old(name); Check(f # NIL);
  IF f = NIL THEN length := 0; NEW(data, 1); RETURN NIL END;
  length := Files.Length(f);
  IF length = 0 THEN NEW(data, 1) ELSE NEW(data, length) END;
  Files.Set(r, f, 0); Files.ReadBytes(r, data^, length); Check(r.res = 0);
  RETURN f
END Load;

PROCEDURE Line(VAR R: Files.Rider; VAR s: ARRAY OF CHAR): BOOLEAN;
VAR c: CHAR; i: LONGINT;
BEGIN
  i := 0; Files.Read(R, c);
  IF R.eof THEN RETURN FALSE END;
  WHILE ~R.eof & (c # 0AX) DO IF i < LEN(s) - 1 THEN s[i] := c; INC(i) END; Files.Read(R, c) END;
  s[i] := 0X; RETURN TRUE
END Line;

PROCEDURE GIF;
VAR img, decoded, riderImage, bad: GIF0.Image; info: GIF0.Info; data, copy, encoded: Files.Bytes;
  f: Files.File; r: Files.Rider; n, m, res, at, i, colors: LONGINT;
BEGIN
  phase := "GIF memory round trips and transparency";
  img := GIF0.NewImage(8, 8); Fill(img.pix^); img.alpha := TRUE;
  img.pix[3] := 0X; img.pix[7] := 0FFX;
  GIF0.EncodeBytes(img, 65536, data, n, res); Check((res = GIF0.ok) & (n > 0) & (data # NIL));
  GIF0.ReadInfoBytes(data^, n, info, res); Check((res = GIF0.ok) & (info.width = 8) & (info.height = 8) & (info.images = 1));
  GIF0.DecodeBytes(data^, n, 64, decoded, res); Check((res = GIF0.ok) & (decoded # NIL) & decoded.alpha);
  Check((decoded.pix[3] = 0X) & (decoded.pix[7] = 0FFX));
  f := Files.FromBytes(data^, n); Files.Set(r, f, 0); GIF0.Decode(r, riderImage, res);
  Check((res = GIF0.ok) & Equal(decoded.pix^, riderImage.pix^, 8 * 8 * 4));
  f := Files.NewMemory(65536); Files.Set(r, f, 0); GIF0.Encode(r, img, res); copy := Files.MemoryData(f, m);
  Check((res = GIF0.ok) & (m = n) & Equal(data^, copy^, n));

  phase := "GIF limits and malformed buffers";
  GIF0.DecodeBytes(data^, n, 63, decoded, res); Check((res = GIF0.tooLarge) & (decoded = NIL));
  GIF0.DecodeBytes(data^, n, 0, decoded, res); Check((res = GIF0.tooLarge) & (decoded = NIL));
  GIF0.DecodeBytes(data^, -1, GIF0.MaxPixels, decoded, res); Check((res = GIF0.badFormat) & (decoded = NIL));
  GIF0.DecodeBytes(data^, LEN(data^) + 1, GIF0.MaxPixels, decoded, res); Check((res = GIF0.badFormat) & (decoded = NIL));
  GIF0.DecodeBytes(data^, 5, GIF0.MaxPixels, decoded, res); Check((res # GIF0.ok) & (decoded = NIL));
  GIF0.EncodeBytes(img, n - 1, encoded, m, res); Check((res = GIF0.tooLarge) & (encoded = NIL) & (m = 0));
  GIF0.EncodeBytes(img, n, encoded, m, res); Check((res = GIF0.ok) & (m = n) & Equal(data^, encoded^, n));
  GIF0.EncodeBytes(img, 0, encoded, m, res); Check((res = GIF0.tooLarge) & (encoded = NIL) & (m = 0));
  colors := 2; FOR i := 1 TO ORD(data[10]) MOD 8 DO colors := colors * 2 END;
  at := 13 + colors * 3;
  IF data[at] = 21X THEN INC(at, 8) END;
  Check(data[at] = 2CX);
  data[6] := 1X; data[7] := 0X; data[8] := 1X; data[9] := 0X;
  data[at + 1] := 64X; data[at + 2] := 0X;
  GIF0.DecodeBytes(data^, n, 64, decoded, res); Check((res = GIF0.tooLarge) & (decoded = NIL));
  NEW(bad); bad.width := 2; bad.height := 2; NEW(bad.pix, 3);
  GIF0.EncodeBytes(bad, 4096, encoded, m, res); Check((res = GIF0.noImage) & (encoded = NIL) & (m = 0));
  bad.width := 65535; bad.height := 65535;
  GIF0.EncodeBytes(bad, 4096, encoded, m, res); Check((res = GIF0.tooLarge) & (encoded = NIL) & (m = 0))
END GIF;

PROCEDURE Fixture(VAR name: ARRAY OF CHAR);
VAR f: Files.File; r: Files.Rider; data: Files.Bytes; length, a, b: LONGINT; g, gc: GIF0.Image; gi, gic: GIF0.Info;
BEGIN
  COPY(name, phase); f := Load(name, data, length);
  IF f = NIL THEN RETURN END;
  Files.Set(r, f, 0); GIF0.ReadInfo(r, gi, a); GIF0.ReadInfoBytes(data^, length, gic, b); Check(a = b);
  IF a = GIF0.ok THEN
    Check((gi.width = gic.width) & (gi.height = gic.height) & (gi.colors = gic.colors) &
      (gi.images = gic.images) & (gi.interlaced = gic.interlaced) & (gi.transparent = gic.transparent))
  END;
  Files.Set(r, f, 0); GIF0.Decode(r, g, a); GIF0.DecodeBytes(data^, length, GIF0.MaxPixels, gc, b); Check(a = b);
  IF a = GIF0.ok THEN
    Check((gc # NIL) & (g.width = gc.width) & (g.height = gc.height) & (g.alpha = gc.alpha));
    Check((gc # NIL) & Equal(g.pix^, gc.pix^, g.width * g.height * 4))
  ELSE Check(gc = NIL)
  END;
  Files.Close(f)
END Fixture;

(** GIFMemoryTest.Run: memory round trips and limits *)
PROCEDURE Run*;
BEGIN
  checks := 0; failed := 0; GIF;
  out.String("GIFMemoryTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

(** GIFMemoryTest.Fixtures list: the byte-array entry points against the rider ones on every picture of list *)
PROCEDURE Fixtures*;
VAR A: Texts.Reader; f: Files.File; r: Files.Rider; list: ARRAY 256 OF CHAR; line, name: ARRAY 256 OF CHAR; i: LONGINT;
BEGIN
  checks := 0; failed := 0; Texts.OpenArgs(A);
  IF ~Texts.Arg(A, list) THEN out.String("usage: GIFMemoryTest.Fixtures gifsuite.list"); out.Ln; RETURN END;
  f := Files.Old(list);
  IF f = NIL THEN out.String("FAIL no "); out.String(list); out.Ln; RETURN END;
  Files.Set(r, f, 0);
  WHILE Line(r, line) DO
    i := 0; WHILE (line[i] > " ") & (i < LEN(name) - 1) DO name[i] := line[i]; INC(i) END;
    name[i] := 0X;
    IF (i > 0) & (name[0] # "#") THEN Fixture(name) END
  END;
  out.String("GIFMemoryTest fixtures: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Fixtures;

END GIFMemoryTest.
