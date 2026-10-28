MODULE GIFPicturesTest;  (* loksh GIFPicturesTest.Run: GIF pictures through Pictures; needs the desktop's display *)

(* with pictures of gifsuite.tgz in the current directory: Pictures.Open gives a picture of their size,
  in the colours of the palette of Display nearest to those of the picture (transparent pixels white):
  the mean difference of the components, averaged over blocks of 4 by 4 pixels, is less than 20. The
  pictures: c256.gif (256 colours), transp.gif (with a transparent colour). GIF.Store writes a picture
  that GIF0 reads back with the colours of every pixel of the Picture. *)

IMPORT Files, Pictures, out, GIF0, GIF;

VAR checks, failed: LONGINT;

PROCEDURE Check(what: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ~ok THEN INC(failed); out.String("FAIL "); out.String(what); out.Ln END
END Check;

PROCEDURE Decode(name: ARRAY OF CHAR): GIF0.Image;
VAR f: Files.File; R: Files.Rider; img: GIF0.Image; res: LONGINT;
BEGIN
  f := Files.Old(name); IF f = NIL THEN RETURN NIL END;
  Files.Set(R, f, 0); GIF0.Decode(R, img, res); Files.Close(f);
  IF res # GIF0.ok THEN RETURN NIL END;
  RETURN img
END Decode;

(* the mean difference of the components of the picture name opened with Pictures and decoded by GIF0
  (transparent pixels white), compared as averages over blocks of 4 by 4 pixels, times 10; -1 if it
  cannot be opened *)
PROCEDURE MeanDiff(name: ARRAY OF CHAR): LONGINT;
VAR P: Pictures.Picture; p: GIF0.Image; x, y, bx, by, s, sum, n, k: LONGINT; r, g, b: INTEGER;
  a, c: ARRAY 3 OF LONGINT;
BEGIN
  NEW(P); Pictures.Open(P, name, TRUE); p := Decode(name);
  IF (p = NIL) OR (P.width # p.width) OR (P.height # p.height) OR (P.depth # 8) THEN RETURN -1 END;
  sum := 0; n := 0; by := 0;
  WHILE by + 4 <= p.height DO
    bx := 0;
    WHILE bx + 4 <= p.width DO
      a[0] := 0; a[1] := 0; a[2] := 0; c[0] := 0; c[1] := 0; c[2] := 0; y := by;
      WHILE y < by + 4 DO
        x := bx;
        WHILE x < bx + 4 DO
          Pictures.GetColor(P, Pictures.Get(P, SHORT(x), SHORT(p.height - 1 - y)), r, g, b); s := (y * p.width + x) * 4;
          INC(a[0], r); INC(a[1], g); INC(a[2], b);
          IF p.pix[s + 3] = 0X THEN INC(c[0], 255); INC(c[1], 255); INC(c[2], 255)
          ELSE INC(c[0], ORD(p.pix[s])); INC(c[1], ORD(p.pix[s + 1])); INC(c[2], ORD(p.pix[s + 2]))
          END;
          INC(x)
        END;
        INC(y)
      END;
      k := 0; WHILE k < 3 DO INC(sum, ABS(a[k] - c[k])); INC(k) END;
      INC(n); INC(bx, 4)
    END;
    INC(by, 4)
  END;
  RETURN sum * 10 DIV (3 * 16 * n)
END MeanDiff;

PROCEDURE Case(name: ARRAY OF CHAR);
VAR d: LONGINT;
BEGIN
  d := MeanDiff(name); out.String(name); out.String(": mean difference "); out.Int(d, 0); out.String(" / 10"); out.Ln;
  Check(name, (d >= 0) & (d < 200))
END Case;

(* GIF.Store of the picture name: read back by GIF0, every pixel has the colour of the Picture *)
PROCEDURE Stored(name: ARRAY OF CHAR);
VAR P: Pictures.Picture; f: Files.File; W: Files.Rider; res, x, y, s: LONGINT; img: GIF0.Image; r, g, b: INTEGER; ok: BOOLEAN;
BEGIN
  NEW(P); Pictures.Open(P, name, TRUE);
  f := Files.New("zq_store.gif"); Files.Set(W, f, 0); GIF.Store(P, W, res); Files.Register(f); Files.Close(f);
  img := Decode("zq_store.gif");
  ok := (res = GIF0.ok) & (img # NIL) & (img.width = P.width) & (img.height = P.height); y := 0;
  WHILE ok & (y < P.height) DO
    x := 0;
    WHILE ok & (x < P.width) DO
      Pictures.GetColor(P, Pictures.Get(P, SHORT(x), SHORT(P.height - 1 - y)), r, g, b); s := (y * P.width + x) * 4;
      ok := (ORD(img.pix[s]) = r) & (ORD(img.pix[s + 1]) = g) & (ORD(img.pix[s + 2]) = b) & (img.pix[s + 3] = 0FFX);
      INC(x)
    END;
    INC(y)
  END;
  Check("GIF.Store", ok)
END Stored;

PROCEDURE Run*;
BEGIN
  checks := 0; failed := 0;
  Case("c256.gif"); Case("transp.gif"); Stored("c256.gif");
  out.String("GIFPicturesTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

END GIFPicturesTest.
