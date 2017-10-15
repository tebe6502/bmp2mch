(*

 BMP2MCH

 changes:
 07.01.2010/12.01.2014/16.04.2015/19.04.2015

*)

program bmp2mch;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, Graphics, Messages, ShellApi, ToolWin, GifImg,
  ExtCtrls, PngImage;

type
  tYUV  = record
           y,u,v: double;
          end;

  CieLab = record
            l,a,b: double;
           end;

var

 ic: array [0..255] of integer;

 pal_sort: array [0..255] of record
                              ile: integer;
                              idx: byte;
                             end;

 mic: array [0..40*1024] of byte;

 dpal: array [0..4, 0..1023] of byte;

 buf, buf4, buf5: array [0..512*1024] of byte;

 invers: array [0..39, 0..127] of Boolean;

 bayer : array [0..15, 0..15] of integer;

 defPal: array [0..17] of TColor;

 hlp, err: integer;

 level: integer = -1;
 
 threshold: integer = 64;

 ncolors: integer = 5;

 colors: integer;

 szerokosc: integer = 160;
 wysokosc: integer = 240;
 step: integer = 1024;

 ftype: byte;

 fMax: Boolean = false;
 resize: Boolean = false;
 grayscale: Boolean = false;
 forceBackground: Boolean = false;

 finput, foutput: string;

 p: TMaxLogPalette;

  bmpHeader : packed record
                    bftype:word;
                    bfsize:longint;
                    bfreserv1:word;
                    bfreserv2:word;
                    bfoffbits:longint;

                    bisize:longint;
                    biwidth:longint;
                    biheight:longint;
                    biplanes:word;
                    bibitcount:word;
                    bicompress:longint;
                    bisizeimage:longint;
                    biXPelsPerMeter:longint;
                    biYPelsPerMeter:longint;
                    biClrUsed:longint;
                    biClrImportant:longint;
                 end;
const

 _mic = $80;
 _fnt = $40;
 _mch = $20;

 AtariPal: array [0..255] of TColor=
 ($00000000, $003B3B3B, $00494949, $00575757,
 $00656565, $00737373, $00818181, $008F8F8F,
 $009D9D9D, $00ABABAB, $00B9B9B9, $00C7C7C7,
 $00D5D5D5, $00E3E3E3, $00F1F1F1, $00FFFFFF,
 $0000235C, $0000316A, $00003F78, $000A4D86,
 $00185B94, $002669A2, $003477B0, $004285BE,
 $005093CC, $005EA1DA, $006CAFE8, $007ABDF6,
 $0088CBFF, $0096D9FF, $00A4E7FF, $00B2F5FF,
 $00091469, $00172277, $00253085, $00333E93,
 $00414CA1, $004F5AAF, $005D68BD, $006B76CB,
 $007984D9, $008792E7, $0095A0F5, $00A3AEFF,
 $00B1BCFF, $00BFCAFF, $00CDD8FF, $00DBE6FF,
 $00380A6C, $0046187A, $00542688, $00623496,
 $007042A4, $007E50B2, $008C5EC0, $009A6CCE,
 $00A87ADC, $00B688EA, $00C496F8, $00D2A4FF,
 $00E0B2FF, $00EEC0FF, $00FCCEFF, $00FFDCFF,
 $00650564, $00731372, $00812180, $008F2F8E,
 $009D3D9C, $00AB4BAA, $00B959B8, $00C767C6,
 $00D575D4, $00E383E2, $00F191F0, $00FF9FFE,
 $00FFADFF, $00FFBBFF, $00FFC9FF, $00FFD7FF,
 $00890752, $00971560, $00A5236E, $00B3317C,
 $00C13F8A, $00CF4D98, $00DD5BA6, $00EB69B4,
 $00F977C2, $00FF85D0, $00FF93DE, $00FFA1EC,
 $00FFAFFA, $00FFBDFF, $00FFCBFF, $00FFD9FF,
 $009C103A, $00AA1E48, $00B82C56, $00C63A64,
 $00D44872, $00E25680, $00F0648E, $00FE729C,
 $00FF80AA, $00FF8EB8, $00FF9CC6, $00FFAAD4,
 $00FFB8E2, $00FFC6F0, $00FFD4FE, $00FFE2FF,
 $009C1E1F, $00AA2C2D, $00B83A3B, $00C64849,
 $00D45657, $00E26465, $00F07273, $00FE8081,
 $00FF8E8F, $00FF9C9D, $00FFAAAB, $00FFB8B9,
 $00FFC6C7, $00FFD4D5, $00FFE2E3, $00FFF0F1,
 $00892E07, $00973C15, $00A54A23, $00B35831,
 $00C1663F, $00CF744D, $00DD825B, $00EB9069,
 $00F99E77, $00FFAC85, $00FFBA93, $00FFC8A1,
 $00FFD6AF, $00FFE4BD, $00FFF2CB, $00FFFFD9,
 $00653E00, $00734C03, $00815A11, $008F681F,
 $009D762D, $00AB843B, $00B99249, $00C7A057,
 $00D5AE65, $00E3BC73, $00F1CA81, $00FFD88F,
 $00FFE69D, $00FFF4AB, $00FFFFB9, $00FFFFC7,
 $00384B00, $00465900, $00546709, $00627517,
 $00708325, $007E9133, $008C9F41, $009AAD4F,
 $00A8BB5D, $00B6C96B, $00C4D779, $00D2E587,
 $00E0F395, $00EEFFA3, $00FCFFB1, $00FFFFBF,
 $00095200, $00176000, $00256E0C, $00337C1A,
 $00418A28, $004F9836, $005DA644, $006BB452,
 $0079C260, $0087D06E, $0095DE7C, $00A3EC8A,
 $00B1FA98, $00BFFFA6, $00CDFFB4, $00DBFFC2,
 $00005300, $0000610B, $00006F19, $000A7D27,
 $00188B35, $00269943, $0034A751, $0042B55F,
 $0050C36D, $005ED17B, $006CDF89, $007AED97,
 $0088FBA5, $0096FFB3, $00A4FFC1, $00B2FFCF,
 $00004E13, $00005C21, $00006A2F, $0000783D,
 $0000864B, $000B9459, $0019A267, $0027B075,
 $0035BE83, $0043CC91, $0051DA9F, $005FE8AD,
 $006DF6BB, $007BFFC9, $0089FFD7, $0097FFE5,
 $0000432D, $0000513B, $00005F49, $00006D57,
 $00007B65, $00018973, $000F9781, $001DA58F,
 $002BB39D, $0039C1AB, $0047CFB9, $0055DDC7,
 $0063EBD5, $0071F9E3, $007FFFF1, $008DFFFF,
 $00003346, $00004154, $00004F62, $00005D70,
 $00006B7E, $000B798C, $0019879A, $002795A8,
 $0035A3B6, $0043B1C4, $0051BFD2, $005FCDE0,
 $006DDBEE, $007BE9FC, $0089F7FF, $0097FFFF);



function clip(a: real): byte;
begin

 if a>255 then
  Result:=255
 else
  Result:=round(a);

end;


function RGBtoYUV(const cl: TColor): tYUV;
var r,g,b: byte;
begin

 r:=GetRValue(cl);
 g:=GetGValue(cl);
 b:=GetBValue(cl);

 Result.y := 0.299*r + 0.587*g + 0.114*b;
 Result.u := 0.565*(b - Result.y);
 Result.v := 0.713*(r - Result.y);

end;


// funkcje do wygenerowanie tablicy Bayer'a
function pow(a: Integer; b: Integer): Integer;
begin
   result := 1;
   while (b > 0) do
   begin
      result := result * a;
      b := b - 1;
   end;
end;

function getX(i: Integer; level: Integer; shift: Integer): Integer;
begin

   result := ((i+1) mod 2);

   if (level = 1) then
   begin
      result := result + shift;
      exit;
   end;

   result := getX(i div 4, level-1, shift + result * pow(2, level-1));
end;

function getY(i: Integer; level: Integer; shift: Integer): Integer;
begin
   result := (((i+3) mod 4) div 2);

   if (level = 1) then
   begin
      result := result + shift;
      exit;
   end;

   result := getY(i div 4, level-1, shift + result * pow(2, level-1));
end;

procedure prepareBayerTable(level: Integer);
var
   size, i, x, y: Integer;
begin
   size := pow(2, level);

   for i:=1 to size*size do
   begin
      x := getX(i-1, level, 0);
      y := getY(i-1, level, 0);

      bayer[x][y] := i;
   end;
end;


function findNearest(v: byte; o: real; nc: byte): byte;
var w,d: double;
    k: byte;
    a,b: tYUV;
begin

 Result:=0;

 if level<0 then o:=0;

 if forceBackground then
 if rgb(p.palPalEntry[v].peRed, p.palPalEntry[v].peGreen, p.palPalEntry[v].peBlue) = defPal[0] then o:=0;

 a:=RGBtoYUV( rgb(clip(p.palPalEntry[v].peRed+o), clip(p.palPalEntry[v].peGreen+o), clip(p.palPalEntry[v].peBlue+o) ));

 b:=RGBtoYUV( defPal[0] );
 d:=Sqr(b.y - a.y) + Sqr(b.u - a.u) + Sqr(b.v - a.v);
 
 for k:=0 to nc-1 do begin

  b:=RGBtoYUV( defPal[k] );

  w := Sqr(b.y - a.y) + Sqr(b.u - a.u) + Sqr(b.v - a.v);

  if d>w then begin d:=w; Result:=k end;

 end;

end;


{** A power function from Jack Lyle. Said to be more powerful than the
    Pow function that comes with Delphi. }
function Power2(Base, Exponent : Double) : Double;
{ raises the base to the exponent }
  CONST
    cTiny = 1e-15;

  VAR
    Power : Double; { Value before sign correction }

  BEGIN
    Power := 0;
    { Deal with the near zero special cases }
    IF (Abs(Base) < cTiny) THEN BEGIN
      Base := 0.0;
    END; { IF }
    IF (Abs(Exponent) < cTiny) THEN BEGIN
      Exponent := 0.0;
    END; { IF }

    { Deal with the exactly zero cases }
    IF (Base = 0.0) THEN BEGIN
      Power := 0.0;
    END; { IF }
    IF (Exponent = 0.0) THEN BEGIN
      Power := 1.0;
    END; { IF }

    { Cover everything else }
    IF ((Base < 0) AND (Exponent < 0)) THEN
        Power := 1/Exp(-Exponent*Ln(-Base))
    ELSE IF ((Base < 0) AND (Exponent >= 0)) THEN
        Power := Exp(Exponent*Ln(-Base))
    ELSE IF ((Base > 0) AND (Exponent < 0)) THEN
        Power := 1/Exp(-Exponent*Ln(Base))
    ELSE IF ((Base > 0) AND (Exponent >= 0)) THEN
        Power := Exp(Exponent*Ln(Base));

    { Correct the sign }
    IF ((Base < 0) AND (Frac(Exponent/2.0) <> 0.0)) THEN
      Result := -Power
    ELSE
      Result := Power;
END; { FUNCTION Pow }


function RGB2CIELab(var cl: TColor): CieLab;
var e,k, r,g,b, x,y,z: double;
begin

    Result.l:=0;
    Result.a:=0;
    Result.b:=0;

    e:= (216.0/24389.0);
    k:= (24389.0/27.0);

    R := GetRValue(cl) / 255.0;
    G := GetGValue(cl) / 255.0;
    B := GetBValue(cl) / 255.0;

    if (R > 0.04045) then
        R := power2(( ( R + 0.055 ) / 1.055 ), 2.4)
    else
        R := R / 12.92;

    if (G > 0.04045) then
        G := power2(( ( G + 0.055 ) / 1.055 ), 2.4)
    else
        G := G / 12.92;

    if (B > 0.04045) then
        B := power2(( ( B + 0.055 ) / 1.055 ), 2.4)
    else
        B := B / 12.92;

    x := (R * 0.4124564 + G * 0.3575761 + B * 0.1804375);
    y := (R * 0.2126729 + G * 0.7151522 + B * 0.0721750);
    z := (R * 0.0193339 + G * 0.1191920 + B * 0.9503041);

    //Algo XYZ to LAB

    x := x / 95.047;
    y := y / 100.0;
    z := z / 108.883;

    if (x > e) then
        x := power2(x, (1.0/3.0))
    else
        x := (((k * x) + 16.0) / 116.0);

    if (y > e) then
        y := power2(y, (1.0/3.0))
    else
        y := (((k * y) + 16.0) / 116.0);

    if (z > e) then
        z := power2(z, (1.0/3.0))
    else
        z := (((k * z) + 16.0) / 116.0);

    Result.l := (116.0 * y) - 16.0;
    Result.a := 500.0 * (x - y);
    Result.b := 200.0 * (y - z);

end;


function Cie94(col1,col2: TColor): double;
var cl1,cl2: CieLab;
    dL, C1, C2, dA, dB, dC, dH: double;
    KL, K1, K2, SL, SC, SH: double;
begin

 cl1:=RGB2CieLab(col1);
 cl2:=RGB2CieLab(col2);

 dL := cl1.l - cl2.l;
 C1 := sqrt( sqr(cl1.a) + sqr(cl1.b) );
 C2 := sqrt( sqr(cl2.a) + sqr(cl2.b) );
 dC := C1 - C2;
 dA := cl1.a - cl2.a;
 dB := cl1.b - cl2.b;
 dH := sqrt( sqr(dA) + sqr(dB) - sqr(dC) );

 KL:=1;
 K1:=0.045;
 K2:=0.015;

 SL := 1;
 SC := 1 + K1*C1;
 SH := 1 + K2*C1;

 Result:=sqrt( sqr(dL/SL) + sqr(dC/SC) + sqr(dH/SH) );

end;


function RGB2Atari(const cl: TColor): byte;
var a,b: tYUV;
    i: byte;
    x,p: double;
begin

 Result:=0;

 a:=RGBtoYUV(cl);

 b:=RGBtoYUV(AtariPal[0]);

 x:=Sqr(b.y - a.y) + Sqr(b.u - a.u) + Sqr(b.v - a.v);

// x:=Cie94(cl, AtariPal[0]);

 for i:=0 to 255 do begin

   b:=RGBtoYUV(AtariPal[i]);

   p := Sqr(b.y - a.y) + Sqr(b.u - a.u) + Sqr(b.v - a.v);

//   p:=Cie94(cl, AtariPal[i]);

   if x>p then begin x:=p; Result:=i and $fe end;

  end;

end;


function findMax(a,b, k: byte): byte;
(*----------------------------------------------------------------------------*)
(* znajdujemy najwiekszy element, inny niz poprzedni element z defPal         *)
(*----------------------------------------------------------------------------*)
var i: byte;
    max: integer;
    c: integer;
begin

 Result:=pal_sort[a].idx;
 max:=0;

 if k=0 then
  c:=-1
 else
  c:=RGB2Atari(defPal[k-1]);

 for i:=a to b do
  if (pal_sort[i].ile>max) and
     (RGB2Atari(rgb(p.palPalEntry[pal_sort[i].idx].peRed, p.palPalEntry[pal_sort[i].idx].peGreen, p.palPalEntry[pal_sort[i].idx].peBlue))<>c) then begin

   max:=pal_sort[i].ile;
   Result:=pal_sort[i].idx;
  end;

end;


function GetTempFile(const Extension: string): string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  repeat
    GetTempPath(SizeOf(Buffer) - 1, Buffer);
    GetTempFileName(Buffer, '~', 0, Buffer);
    Result := ChangeFileExt(Buffer, Extension);
  until not FileExists(Result);
end;


procedure LoadBMP(fnam: string);
(*----------------------------------------------------------------------------*)
(* I M P O R T  I N D E X E D  B I T M A P                                    *)
(*----------------------------------------------------------------------------*)
var i, j, x, y: integer;
    bmp: TBitmap;
    K: PByteArray;
begin

 bmp:=TBitmap.Create;
 bmp.LoadFromFile(fnam);

 if bmp.PixelFormat<>pf8bit then begin
  writeln('Only 8 Bits Per Pixel !');
  bmp.Free;
  halt;
 end;

 GetPaletteEntries(Bmp.Palette, 0, 256, p.palPalEntry);

// for i := 0 to 255 do writeln(p.palPalEntry[i].peRed,',',p.palPalEntry[i].peGreen,',', p.palPalEntry[i].peBlue);

 x:=bmp.width;

 if resize then begin

  if x shr 1<=128 then x:=128 else
   if x shr 1<=160 then x:=160 else
    x:=192;

 end else
  if x<=128 then x:=128 else
   if x<=160 then x:=160 else
    x:=192;

 y:=bmp.Height; if y>1024 then y:=1024;

 if y>240 then Wysokosc := y;

 szerokosc:=x;

 for j:=0 to y-1 do begin
  K:=bmp.ScanLine[j];

  if resize then
   for i:=0 to Szerokosc-1 do buf[i+j*Szerokosc]:=K[i*2]
  else
   move(K[0], buf[j*Szerokosc], x);

 end;

 bmp.Free;
end;


function PNGBitsForPixel(const AColorType,  ABitDepth: Byte): Integer;
begin
  case AColorType of
    COLOR_GRAYSCALEALPHA: Result := (ABitDepth * 2);
    COLOR_RGB:  Result := (ABitDepth * 3);
    COLOR_RGBALPHA: Result := (ABitDepth * 4);
    COLOR_GRAYSCALE, COLOR_PALETTE:  Result := ABitDepth;
  else
      Result := 0;
  end;
end;


procedure ExportBMP(t: TCanvas; fnam: string; w,h: integer);
(*----------------------------------------------------------------------------*)
(* E X P O R T  A S -> indexed B M P                                          *)
(*----------------------------------------------------------------------------*)
var i,j, FileHandle: integer;
    temp: array [0..511] of byte;
    Index: byte;
    cl: TColor;

const RConst = 77;
      GConst = 150;
      BConst = 29;
begin

 with bmpheader do begin
  bftype:=256*ord('M')+ord('B');
  bisize:=40;
  biwidth:=w;                               { szerokosc w pixlach }
  biheight:=h;  { wysokosc }
  bfoffbits:=14+bisize+1024;
  bisizeimage:=biwidth*biheight;
  bfsize:=bfoffbits+bisizeimage;

  biClrUsed:=$100;         { liczba kolorow = max 256 }
  biClrImportant:=0;
  biXPelsPerMeter:=0;
  biYPelsPerMeter:=0;
  bfreserv1:=0;
  bfreserv2:=0;
  bicompress:=0;
  biplanes:=1;
  bibitcount:=8;           { liczba bitow na pixel }
 end;

 FileHandle := FileCreate(fnam);
 try

 FileWrite(FileHandle, bmpheader, sizeof(bmpheader));

 for i:=0 to 255 do begin
  temp[0]:=i;
  temp[1]:=i;
  temp[2]:=i;
  temp[3]:=0;

  FileWrite(FileHandle, temp,4);
 end;


 for j:=h-1 downto 0 do begin
  for i:=0 to w-1 do begin

   cl:=t.Pixels[i,j];
   Index := byte((GetRValue(cl)*RConst + GetGValue(cl)*GConst + GetBValue(cl)*BConst) shr 8);

   temp[i]:=Index;
  end;

  FileWrite(FileHandle, temp, w);
 end;

 finally
  FileClose(FileHandle);
 end;

end;


procedure LoadPNG(fnam:string);
var PNG: TPngObject;
    bmp: TBitmap;
    img: Timage;
    ftemp: string;
begin

  ftemp:=GetTempFile('.~bmp');

  PNG := TPNGObject.Create;
  bmp := TBitmap.Create;
  try
    PNG.LoadFromFile(fnam);

    if PNGBitsForPixel( PNG.Header.ColorType, PNG.Header.BitDepth ) <> 8 then begin

      if grayscale then begin

       ExportBMP(PNG.Canvas, ftemp, PNG.Width, PNG.Height);    // jesli obrazek 24bit to pozwala zamienic na 8bit   

      end else begin
       writeln('Only 8 Bits Per Pixel !');
       PNG.Free;
       bmp.Free;
       halt;
      end;

    end else begin

     img:=TImage.Create(nil);       // !!! ta metoda gwarantuje ze nie zmieni sie paleta jak przez BMP.ASSIGN(PNG) dla pf8bit

     img.Picture.Bitmap.PixelFormat := pf8bit;
     img.Picture.Bitmap.Height := PNG.Height;
     img.Picture.Bitmap.Width := PNG.Width;
     if PNGBitsForPixel( PNG.Header.ColorType, PNG.Header.BitDepth )=8 then img.Picture.Bitmap.Palette := PNG.Palette;
     img.Canvas.Draw(0,0,PNG);
     img.Picture.Bitmap.PaletteModified := true;

     img.Picture.Bitmap.SaveToFile(ftemp);
     img.Free;
     
    end;

    LoadBMP(ftemp);

  finally
   PNG.Free;
   bmp.Free;
  end;

end;


procedure CreatePal(y: integer);
var i,j, old: integer;
    v: byte;
    r: real;
begin

 for i := 0 to 255 do begin
  ic[i]:=0;
  pal_sort[i].ile:=0;
  pal_sort[i].idx:=0;
 end;


 for j:=y to y+step-1 do
  for i:=0 to szerokosc-1 do inc(ic[buf[i+j*Szerokosc]]);           // zliczamy kolory


// zliczamy kolory wystepujace na obrazie, pomijamy nie uzywane
 colors:=0;

 for i:=0 to 255 do
   if ic[i]>0 then begin

    pal_sort[colors].ile:=ic[i];
    pal_sort[colors].idx:=i;

    ic[i]:=0;

    inc(colors);
  end;


  writeln('Colors: ',colors);

// sortuje palete kolorow obrazka od najwiekszej do najmniejszej liczby wystapien

 if fMax then 

 for j:=0 to colors-1 do
   for i:=0 to colors-1 do
     if pal_sort[i].ile < pal_sort[j].ile then begin

         old:=pal_sort[j].ile;

         pal_sort[j].ile:=pal_sort[i].ile;
         pal_sort[i].ile:=old;

         old:=pal_sort[j].idx;

         pal_sort[j].idx:=pal_sort[i].idx;
         pal_sort[i].idx:=old;
        end;


// dziele liczbe kolorow obrazka COLORS przez liczbe kolorow palety NCOLORS
// dla kazdego takiego przedzialu znajduje najczesciej wystepujaca wartosc

 r:=colors/ncolors;

 if colors<=ncolors then  // wyjatek liczba kolorow w zakresie dostepnych
  for i:=0 to ncolors-1 do defPal[i]:=rgb(p.palPalEntry[pal_sort[i].idx].peRed, p.palPalEntry[pal_sort[i].idx].peGreen, p.palPalEntry[pal_sort[i].idx].peBlue)
 else
  for i:=0 to ncolors-1 do begin
   v:=findMax( round(i*r)+(1*ord(i<>0)), round(i*r+r), i );
   defPal[i]:=rgb(p.palPalEntry[v].peRed, p.palPalEntry[v].peGreen, p.palPalEntry[v].peBlue);
  end;
{
  defpal[0]:=0;
  defpal[1]:=AtariPal[2];
  defpal[2]:=AtariPal[6];
  defpal[3]:=AtariPal[10];
  defpal[4]:=AtariPal[14];
}

// defpal zawiera teraz NCOLORS najczesciej wystepujacych w zadanym zakresie palety kolorow obrazka

  for i:=0 to 4 do
   for j:=y to y+step-1 do dpal[i,j]:=RGB2Atari(defPal[i]);

end;


procedure saveMICfile(fnam: string);
var zm: string;
    plik, i,j, Bytes: integer;
begin

  zm:=ChangeFileExt(fnam, '.mic');

  writeln('Save ',zm,' file');

  Bytes:=Szerokosc shr 2;

  plik:=FileCreate(zm);
  FileWrite(plik, mic, Wysokosc*Bytes);
  FileClose(plik);

  zm:=ChangeFileExt(zm, '.col');

  writeln('Save ',zm,' file');
  
  plik:=FileCreate(zm);

 // paleta kolorow
  for i:=0 to 4 do
   for j := 0 to Wysokosc - 1 do
    FileWrite(plik, dpal[i,j], 1);

  FileClose(plik);
end;


procedure saveMCHfile(fnam: string);
var zm: string;
    plik, i,j, y, Bytes: integer;
    v: byte;
begin

 zm:=ChangeFileExt(fnam, '.mch');

 writeln('Save ',zm,' file');

 plik:=FileCreate(zm);

 Bytes:=Szerokosc shr 2;

 for j:=0 to (Wysokosc shr 3)-1 do
  for i:=0 to Bytes-1 do begin

   v:=ord(invers[i][j])*$80;

   if (i=0) and (j=0) then v:=v or 5;

   FileWrite(plik, v, 1);

   for y:=0 to 7 do FileWrite(plik, mic[i+j*(8*Bytes)+y*Bytes], 1);

  end;

  for i:=0 to 4 do
   for j:=0 to 239 do FileWrite(plik, dpal[i,j], 1);

  FileClose(plik);
end;


procedure saveFNTfile(fnam: string);
var zm: string;
    plik, i,j, k, bytes: integer;
begin

  zm:=ChangeFileExt(fnam, '.fnt');

  writeln('Save ',zm,' file');

  fillchar(buf, sizeof(buf), 0);

  plik:=FileCreate(zm);

  bytes:=Szerokosc shr 2;

  for j := 0 to Wysokosc shr 3 - 1 do begin

   for i := 0 to Bytes - 1 do
    for k := 0 to 7 do FileWrite(plik, mic[i+j*(8*Bytes)+k*Bytes], 1);

   FileWrite(plik, buf, 1024-(Bytes*8));    // uzupelnij zerami do konca zestawu

  end;

  FileClose(plik);

end;


procedure cnv(fnam: string);
var i,j, k, bayerSize, Bytes: integer;
    ext: string;
    v, h: byte;
    p: array [0..4] of byte;
    e: real;
begin

 ext:=AnsiUpperCase(ExtractFileExt(fnam));

 if ext='.BMP' then
  LoadBMP(fnam)
 else
  if ext='.PNG' then
   LoadPNG(fnam)
  else begin
   Writeln(fnam, ' not supported format');
   halt;
  end;


 if level<0 then begin
  bayerSize:=1000;
  e:=1;
 end else begin
  prepareBayerTable(level+1);
  bayerSize:=pow(2,level+1);
  e := threshold / (bayerSize*bayerSize);
 end;


 Bytes:=Szerokosc shr 2;

 for j:=0 to Wysokosc-1 do begin

  if j mod step=0 then CreatePal(j);

//  writeln(format('Range #%.3d - %.3d colors',[j,colors]));

  for i:=0 to Szerokosc-1 do begin
   buf4[i+j*Szerokosc]:=findNearest(buf[i+j*Szerokosc], e * bayer[i mod bayerSize][j mod bayerSize], 4);
   buf5[i+j*Szerokosc]:=findNearest(buf[i+j*Szerokosc], e * bayer[i mod bayerSize][j mod bayerSize], 5);
  end;
 end;

 if ncolors<>5 then move(buf4, buf5, sizeof(buf5));


 for j:=0 to Wysokosc - 1 do
  for i:=0 to Bytes - 1 do begin

   for k:=0 to 3 do begin
    h:=buf5[i*4+k+j*Szerokosc];

    if h>3 then begin h:=3; invers[i][j shr 3]:=true end;

    p[k]:=h;
   end;

   v:=p[0] shl 6+
      p[1] shl 4+
      p[2] shl 2+
      p[3];

   mic[i+j*Bytes]:=v;
  end;


 writeln(format('Width: %d, Height: %d', [Szerokosc, Wysokosc]));

 if foutput<>'' then fnam:=foutput;

 if ftype and _fnt<>0 then saveFNTfile(fnam);
 
  if Wysokosc>240 then                  // MCH nie zapisuje wiecej niz 240 linii
   if ftype and _mch<>0 then begin ftype:=(ftype xor _mch) or _mic end;

 if ftype and _mch<>0 then saveMCHfile(fnam);
   
 if ftype and _mic<>0 then saveMICfile(fnam);

end;


procedure Syntax;
begin

  writeln('bmp2mch v2.3');
  writeln('bmp2mch finput.raw [-option] [-ofilename]'#13#10);
  writeln('-r'#9'horizontal resize');
  writeln('-g'#9'load bitmap as grayscale');
  writeln('-m'#9'color palette sort descending (default ascending)');
  writeln('-d0'#9'dither, Bayer matrix 2x2');
  writeln('-d1'#9'dither, Bayer matrix 4x4');
  writeln('-d2'#9'dither, Bayer matrix 8x8');
  writeln('-d3'#9'dither, Bayer matrix 16x16');
  writeln('-f'#9'output file format: MCH (default), MIC, FNT');
  writeln('-t???'#9'threshold <1..256> (default = 64)');
  writeln('-s???'#9'step Y line <1..256> (default = 1024)');
  writeln('-c4'#9'4 colors');
  writeln('-c5'#9'5 colors (default)');
  writeln('-fb'#9'force background');

  halt;
end;



begin

 ftype:=_mch;


 for hlp:=1 to ParamCount do
  if (copy(ParamStr(hlp),1,2)='-D') or (copy(ParamStr(hlp),1,2)='-d') then begin

   case ParamStr(hlp)[3] of

    '0',#0: level := 0;
    '1': level := 1;
    '2': level := 2;
    '3': level := 3;

   else
    Syntax;
   end;

  end else
   if AnsiUpperCase(ParamStr(hlp))='-G' then begin
    grayscale:=true;
   end else
   if AnsiUpperCase(ParamStr(hlp))='-M' then begin
    fMax:=true;
   end else
//   if AnsiUpperCase(copy(ParamStr(hlp),1,2))='-P' then begin

//   end else

   if AnsiUpperCase(ParamStr(hlp))='-FB' then begin

     forceBackground:=true;
   end else
   if AnsiUpperCase(copy(ParamStr(hlp),1,2))='-F' then begin

     if AnsiUpperCase(copy(ParamStr(hlp),3,256))='MIC' then ftype:=ftype or _mic;
     if AnsiUpperCase(copy(ParamStr(hlp),3,256))='FNT' then ftype:=ftype or _fnt;
     if AnsiUpperCase(copy(ParamStr(hlp),3,256))='MCH' then ftype:=ftype or _mch;

     if ftype=0 then Syntax;

   end else
   if AnsiUpperCase(copy(ParamStr(hlp),1,2))='-S' then begin

    val(copy(ParamStr(hlp),3,256), step, err);

    if (err<>0) or (step<1) or (step>256) then Syntax;

   end else
   if AnsiUpperCase(copy(ParamStr(hlp),1,2))='-O' then begin

    foutput:=copy(ParamStr(hlp),3,256);

    if foutput='' then Syntax;

   end else
   if AnsiUpperCase(copy(ParamStr(hlp),1,2))='-T' then begin

    val(copy(ParamStr(hlp),3,256), threshold, err);

    if (err<>0) or (threshold<1) or (threshold>256) then Syntax;

   end else
    if AnsiUpperCase(ParamStr(hlp))='-R' then
     resize:=true
    else
     if AnsiUpperCase(copy(ParamStr(hlp),1,2))='-C' then begin

      if ParamStr(hlp)[3] in ['2','3','4','5'] then
       ncolors:=StrToInt(ParamStr(hlp)[3])
      else
       Syntax;

     end else
      if ParamStr(hlp)[1]='-' then
       Syntax
      else
       finput:=ParamStr(hlp);

 if not(FileExists(finput)) or (ParamCount<1) then Syntax;

 cnv(finput);

end.

