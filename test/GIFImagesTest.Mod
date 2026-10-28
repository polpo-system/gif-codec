MODULE GIFImagesTest;  (* loksh GIFImagesTest.Run: GIF pictures through Images; needs the desktop's display *)

(* with pictures of gifsuite.tgz in the current directory: c256.gif (256 colours), transp.gif (with a
  transparent colour), inter.gif (interlaced). Images.Load gives the pixels of GIF0 (transparent ones
  with alpha 0); Images.Store writes them back, and GIF0 reads the same pixels again. *)

IMPORT Files, Images, out, GIF0;

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

(* does img (Images) have the pixels of p (GIF0) *)
PROCEDURE SameImage(img: Images.Image; p: GIF0.Image): BOOLEAN;
VAR x, y, s, k: LONGINT; mode: Images.Mode; fmt: Images.Format; row: ARRAY 4 OF CHAR;
BEGIN
  IF (img.width # p.width) OR (img.height # p.height) THEN RETURN FALSE END;
  fmt := Images.BGRA8888; Images.InitMode(mode, Images.srcCopy); y := 0;
  WHILE y < p.height DO
    x := 0;
    WHILE x < p.width DO
      Images.GetPixels(img, SHORT(x), SHORT(p.height - 1 - y), 1, fmt, row, mode);
      s := (y * p.width + x) * 4;
      IF row[3] # p.pix[s + 3] THEN RETURN FALSE END;
      k := 0;
      WHILE k < 3 DO  (* row: blue, green, red *)
        IF row[k] # p.pix[s + 2 - k] THEN RETURN FALSE END;
        INC(k)
      END;
      INC(x)
    END;
    INC(y)
  END;
  RETURN TRUE
END SameImage;

PROCEDURE Same(a, b: GIF0.Image): BOOLEAN;
VAR i, n: LONGINT;
BEGIN
  IF (a = NIL) OR (b = NIL) OR (a.width # b.width) OR (a.height # b.height) THEN RETURN FALSE END;
  i := 0; n := a.width * a.height * 4;
  WHILE (i < n) & (a.pix[i] = b.pix[i]) DO INC(i) END;
  RETURN i = n
END Same;

PROCEDURE ImagesCase(name: ARRAY OF CHAR);
VAR img: Images.Image; done: BOOLEAN; p: GIF0.Image; fname: ARRAY 32 OF CHAR;
BEGIN
  p := Decode(name); NEW(img); Images.Load(img, name, done);
  Check(name, done & (p # NIL) & SameImage(img, p));
  IF done THEN
    fname := "zq_store.gif"; Images.Store(img, fname, done);
    Check("Images.Store", done & Same(p, Decode(fname)))
  END
END ImagesCase;

PROCEDURE Run*;
BEGIN
  checks := 0; failed := 0;
  ImagesCase("c256.gif"); ImagesCase("transp.gif"); ImagesCase("inter.gif");
  out.String("GIFImagesTest: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

END GIFImagesTest.
