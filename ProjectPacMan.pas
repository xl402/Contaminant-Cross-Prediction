unit ImageProcessor_tl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,System.Generics.Collections,
  Vcl.Controls,Vcl.Forms, Vcl.Dialogs, Vcl.ExtDlgs,
  Vcl.StdCtrls, Vcl.ExtCtrls,pngimage, math;

type
  TArray=array of integer;
  TPixelMatrix = array of array of smallint;
  TForm1 = class(TForm)
    detector1IN: TImage;
    load1: TButton;
    Edge: TButton;
    OpenPictureDialog1: TOpenPictureDialog;
    Detector1OUT: TImage;
    Memo1: TMemo;
    binary: TButton;
    check: TButton;
    magic1: TButton;
    detector2IN: TImage;
    detector2OUT: TImage;
    load2: TButton;
    detector3IN: TImage;
    detector3OUT: TImage;
    load3: TButton;
    OpenPictureDialog2: TOpenPictureDialog;
    OpenPictureDialog3: TOpenPictureDialog;
    procedure load1Click(Sender: TObject);
    procedure load2Click(Sender: TObject);
    procedure load3Click(Sender: TObject);
    {procedure EdgeClick(Sender: TObject);
    procedure binaryClick(Sender: TObject);
    procedure checkClick(Sender: TObject);}
    procedure magic1Click(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  PixelMatrix: TPixelMatrix;
  WorkingMatrix: TpixelMatrix;
  detector1Matrix:TpixelMatrix;
  detector2Matrix:TpixelMatrix;
  detector3Matrix:TpixelMatrix;
  clusters: TPixelMatrix;
  th1: integer;
  th2: array of integer;
  start: array [0..3]of integer;
  stop: boolean;
implementation
{$R *.dfm}
function BitmapToMatrix(ABitmap: TBitmap;
                        var AMatrix: TPixelMatrix):TPixelMatrix;
//Convert a 8-bit bitmap into a matrix, no support for any other formats!
type
  TRGBBytes = array[0..2] of Byte;
var
  I: Integer;
  X: Integer;
  Y: Integer;
  Size: Integer;
  Pixels: PByteArray;
  SourceColor: TRGBBytes;

const
  TripleSize = SizeOf(TRGBBytes);
begin
   case ABitmap.PixelFormat of
    pf8bit: Size := SizeOf(TRGBTriple);
   end;

  //
  SetLength(AMatrix, ABitmap.width, ABitmap.height);
  for I := 0 to TripleSize - 1 do
    SourceColor[I] := Byte(clWhite shr (16 - (I * 8)));

  for Y := 0 to ABitmap.Height - 1 do
  begin
  Pixels := ABitmap.ScanLine[Y];
  for X := 0 to ABitmap.Width - 1 do AMatrix[X, Y]:= Pixels[(X *round(Size/3))]
  end;
  result:=AMatrix;
end;
procedure MatrixToBitmap(const AMatrix: TPixelMatrix;imageholder:integer);
//Converts Matrix to a bitmap (8 bit)
type
TRGBTripleArray=ARRAY[WORD] OF TRGBTriple;
pRGBTripleArray=^TRGBTripleArray;
VAR
Bitmap:       TBitmap;
ColumnCount:  Integer;
RowCount:     Integer;
i:            Integer;
j :           Integer;
row :         pRGBTripleArray;
xMax:         double;
xMin:         double;
value:        byte;
begin
rowcount := Length(AMatrix[0]);
columncount := Length(AMatrix);
bitmap:= TBitmap.Create;
  TRY
      bitmap.Width := columncount;
      Bitmap.Height := Rowcount;
      bitmap.PixelFormat := pf24bit;
      xMin :=AMatrix[0,0];
      xMax :=AMatrix[0,0];
      for j := 0 to rowcount-1 do
        begin
          for i := 0 to columncount-1 do
            begin
              if AMatrix[i,j] < xMin then xMin := AMatrix[i,j]
              else
                if AMatrix[i,j] > xMax then xMax := AMatrix[i,j]
            end;
        end;

      for j := 0 to rowcount-1 do
          begin
            row := bitmap.ScanLine[j];
            for i := 0 to columncount-1 do
              begin
                value := Round(255*(AMatrix[i,j]-xMin)/(xMax-xMin));
                row[i].rgbtRed := value;
                row[i].rgbtGreen := value;
                row[i].rgbtBlue := value;
              end;
          end;
      case imageholder of
         1:
         begin
         form1.detector1OUT.width :=  bitmap.width;
         form1.detector1OUT.height :=  bitmap.Height;
         form1.detector1OUT.Stretch :=true;
         form1.detector1OUT.picture.graphic := bitmap;
         end;
          2:
         begin
         form1.detector2OUT.width :=  bitmap.width;
         form1.detector2OUT.height :=  bitmap.Height;
         form1.detector2OUT.Stretch :=true;
         form1.detector2OUT.picture.graphic := bitmap;
         end;
          3:
         begin
         form1.detector3OUT.width :=  bitmap.width;
         form1.detector3OUT.height :=  bitmap.Height;
         form1.detector3OUT.Stretch :=true;
         form1.detector3OUT.picture.graphic := bitmap;
         end;
      end;

  FINALLY
  bitmap.Free;
  END;
end;
procedure edgeDetection(Var EMatrix: TPixelMatrix);
//Classic sobel edge detection with standard convolutional kernel
//Result is the root mean square of the sum of two matrixies from convolution
//High complexity (size of image*size of kernel),
//FFT recommended for large images
type
Tkernel= array of array of integer;
VAR
i : integer;
j : integer;
p : integer;
q : integer;
kernel1 : Tkernel;
kernel2 : Tkernel;
Output1: TPixelMatrix;
Output2: TPixelMatrix;
Output3: TPixelMatrix;
begin
SetLength(Output1, Length(EMatrix), Length(EMatrix[0]));
SetLength(Output2, Length(EMatrix), Length(EMatrix[0]));
SetLength(Output3, Length(EMatrix), Length(EMatrix[0]));
kernel1 := [[-1,0,1],[-2,0,2],[-1,0,1]];
kernel2 := [[1,2,1],[0,0,0],[-1,-2,-1]];
{kernel1 := [[0,1,0],[0,1,0],[0,1,0]];
kernel2 := [[0,1,0],[0,1,0],[0,1,0]]; }

  for i := 1 to Length(EMatrix)-2 do
    begin
      for j := 1 to Length(EMatrix[0])-2  do
      begin
         for p := 0 to 2 do
          begin
             for q := 0 to 2 do
             begin
             output1[i,j] := output1[i,j] + kernel1[p,q]*Ematrix[i-1+p,j-1+q];
             end;
          end;
      end;
    end;
  for i := 1 to Length(EMatrix)-2 do
    begin
      for j := 1 to Length(EMatrix[0])-2  do
      begin
         for p := 0 to 2 do
          begin
             for q := 0 to 2 do
             begin
             output2[i,j] := output2[i,j] + kernel2[p,q]*Ematrix[i-1+p,j-1+q];

             end;

          end;

      end;

    end;
for i := 1 to Length(EMatrix)-2 do
    begin
      for j := 1 to Length(EMatrix[0])-2  do
        begin
          output3[i,j] := round(sqrt(sqr(output1[i,j]) + sqr(output2[i,j])));
          if output3[i,j]>255 then output3[i,j]:=255;
        end;
    end;

WorkingMatrix := output3;
end;
procedure ShowPixelMatrix(AMemo: TMemo; const AMatrix: TPixelMatrix);
//used for debugging to show bitmap image as a matrix
var
  S: string;
  X: Integer;
  Y: Integer;
begin
  AMemo.Clear;
  AMemo.Lines.BeginUpdate;
  try
    AMemo.Lines.Add('Matrix size: ' + IntToStr(Length(AMatrix[0])) + 'x' +
      IntToStr(Length(AMatrix)));
    AMemo.Lines.Add('');

    for Y := 0 to High(AMatrix) do
    begin
      S := ' ';
      for X := 0 to High(AMatrix[Y]) - 1 do
      begin
        S := S + IntToStr(AMatrix[Y, X])+' ';
      end;
      AMemo.Lines.Add(S);
    end;
  finally
    AMemo.Lines.EndUpdate;
  end;
end;
procedure ShowArray(AMemo: TMemo; const AMatrix: TPixelMatrix;name:integer);
//used for debugging to show bitmap image as a matrix
var
  S,S1: string;
  Y: Integer;
begin
  AMemo.Lines.BeginUpdate;
  try
    S1:='***********New Image************';
    AMemo.Lines.Add(S1);
    S1:=' ';
    AMemo.Lines.Add(S1);
    case name of
    1:S1:=form1.OpenPictureDialog1.FileName;
    2:S1:=form1.OpenPictureDialog2.FileName;
    3:S1:=form1.OpenPictureDialog3.FileName;
    end;
    AMemo.Lines.Add(S1);
    S1:=' ';
    AMemo.Lines.Add(S1);
    S1:='TH1='+(inttostr(th1))+
     '    TH2=['+(inttostr(th2[0])+','+inttostr(th2[1])
    +']    Starting at: ['+inttostr(start[0])+','+inttostr(start[1])+'], [')
    +inttostr(start[0])+','+inttostr(start[2])+'], ['+inttostr(start[0])+
    ','+inttostr(start[3])+']';
    AMemo.Lines.Add(S1);
    {for Y := 0 to High(AMatrix) do
    begin
      S:=' ';
      S := S + IntToStr(AMatrix[Y, 0])+','+IntToStr(AMatrix[Y, 1]);
      AMemo.Lines.Add(S);
    end; }
  finally
    AMemo.Lines.EndUpdate;
  end;
end;
procedure simpleBinary(Var EMatrix: TPixelMatrix);
//A rudimentary binary image conversion
type
Tkernel= array of array of integer;
VAR
i : integer;
j : integer;
Output: TPixelMatrix;
begin
SetLength(Output, Length(EMatrix), Length(EMatrix[0]));
for i := 1 to Length(EMatrix)-2 do
    begin
      for j := 1 to Length(EMatrix[0])-2  do
      begin
            if Ematrix[i,j]<140 then  output[i,j] :=0;
            if Ematrix[i,j]>140 then  output[i,j] :=255;
      end;
    end;
WorkingMatrix := output;
end;
function isEdge(Amatrix:TPixelMatrix;
         location:array of integer;upwards:boolean):boolean;
//Parameters: Bitmap matrix, coordinate of pixel, upward/downward direction
//Part of contamination detection, checks whether a pixel belongs to part of
//an edge
label checkleft, terminating;
var
a,n,i:integer;  //a: total length of the black straight line. n: gap length
pixel:integer;
begin
if (th2=nil) or (th1=0) then //check whether thresholds are set
  begin
    showmessage('Threshold(s) not set');
  end
else
  begin
    if (location[1]>th2[0]) and (location[1]<th2[1]) then result:=false
    //if within the threshold then it is definitely not within the edge region
    else
    begin
    a:=0; i:=0;n:=0;
    checkleft: //start to look at the left pixel
    i:=i+1;
    if ((location[0]-i)<(length(Amatrix[0])-th1)) or (n>4) then
    //check whether the new location is to the left of th1 or there have been
    //two or more white pixels upwards (too large a gap)
      terminating:
      begin
      if a>0.2*th1 then result:=true
      else result:=false;
      //terminating step where the length of all black pixels is checked
      //showmessage('a='+inttostr(a));
      end
    else
      begin
      pixel:=Amatrix[location[0]-i][location[1]];//record the pixel on the left
      if pixel<>0 then //if the pixel black then increment a and reset n
        begin
          a:=a+1; n:=0;
          goto checkleft;
        end
      else //if pixel to the left is white
        begin
          if(location[1]=0)or(location[1]=length(AMatrix)) then goto terminating
          //if at border of the matrix then go straight to the terminating step
          else
          begin
             case upwards of
             true:
             location[1]:=location[1]-1;
             false:
             location[1]:=location[1]+1;
             end;
             //shift current location upward/downward by one pixel
             location[0]:=location[0]-i+1;
             //update current location (walk along the path of iteration)
             n:=n+1; // record the fact that there has been one (more) gap
             i:=0;
             goto checkleft; //recrusion
          end;
        end;
      end;
    end;
  end;
end;
function lookleft(AMatrix:TPixelmatrix;
         location:array of integer;up:boolean):boolean;
//This looks at the pixel to the left and determine whether it is a part of
//contamination
var
pixel:integer;
  i: Integer;
begin
pixel:=AMatrix[location[0]-1][location[1]];//stores the vale of the left pixel
if pixel=0 then
//if the pixel is black then shit pixel location and keep looking
  begin
  if location[0]>th1 then
    begin
    location[0]:=location[0]-1;
    lookleft(AMatrix,location,up);
    end
    else result:=true//true here is equal to null on flow chart
  end
else
  begin
  if (length(AMatrix)-location[0])<0 then stop:=true//if five pixels from
  //the right then just return termination
  else
    begin
    if isEdge(Amatrix,location,up)=true then stop:=true
    //if its an edge, terminate
    else
      begin
        setlength(clusters,length(clusters)+1,2);
        clusters[high(clusters),0]:=location[0]-1;
        clusters[high(clusters),1]:=location[1];
        location[0]:=location[0]-1;
        lookleft(AMatrix,location,up);
      end;
    end;
  end;
end;
procedure contaminentDetection(AMatrix:TPixelmatrix;
                               location:array of integer;up:boolean);
label turnright,upOneDownOne;
var
pixel: integer;
begin
stop:=false;
upOneDownOne:
if up=true then location[1]:=location[1]-1
else location[1]:=location[1]+1;
turnright:
pixel:= AMatrix[location[0]][location[1]];
if pixel <>255 then
  begin
  location[0]:=location[0]+1;
  goto turnright;
  end;
if stop=true then exit
else
  begin
    lookleft(AMatrix, location,up)
  end;
goto uponedownone;
end;
function borderControl(AMatrix:Tpixelmatrix;bottom:boolean=true):integer;
//A function that returns the location of the edge of the image closer
// to the bottom. Can be used to set th2 and prediction equation
label
goright;
var
pixel,pixelplus,downpixel,downpixelplus,uppixel,uppixelplus,n:integer;
storage:array of integer;
location:array [0..1] of integer;
begin
setlength(storage,1);
storage[0]:=4;
n:=0;
location[0]:=round(length(AMatrix)*3/4);//number of columns*1.5
if bottom=true then location[1]:=length(AMatrix[0])-2//number of rows
else location[1]:=2;//number of rows
pixel:=AMatrix[location[0]][location[1]];
while pixel<>255 do  //if the pixel is black??
  begin
  if bottom=true then location[1]:=location[1]-1 //keep on going up :)
  else location[1]:=location[1]+1; //keep on going down :)
  pixel:=AMatrix[location[0]][location[1]]; //assign pixel value to current pos
  end;
goright:
pixelplus:=AMatrix[location[0]+1][location[1]];//records pixel on the right
downpixel:=AMatrix[location[0]][location[1]+1];//records pixel below
downpixelplus:=AMatrix[location[0]+1][location[1]+1];//records pixel down-right
uppixel:=AMatrix[location[0]][location[1]-1];
uppixelplus:=AMatrix[location[0]+1][location[1]-1];
if bottom=true then
  begin
  while (pixelplus=pixel)and (downpixel=downpixelplus) do
  //as long as neither pixels on the right or below change
    begin
      location[0]:=location[0]+1; n:=n+1;//point location to right and add n
      //(number of steps required)
      pixelplus:=AMatrix[location[0]+1][location[1]];
      downpixel:=AMatrix[location[0]][location[1]+1];
      downpixelplus:=AMatrix[location[0]+1][location[1]+1];
      //re-record all pixel values
    end;
  setlength(storage,(length(storage)+1));
  storage[high(storage)]:=n;//of one of them breaks--add its steps n to storage
  if (pixelplus<>pixel) and (n>round(maxintvalue(storage)/2)) then
  //if an edge reached (going up )and there has
  //been nosignificant change in gradient
  begin
  location[0]:=location[0]+1; location[1]:=location[1]-1;
  n:=0; //reset n and shift position by one up one right
  goto goright;
  end
  else if (downpixelplus<>downpixel) and (n>round(maxintvalue(storage)/2)) then
  begin
    location[0]:=location[0]+1;location[1]:=location[1]+1;
    n:=0;//reset n and shift position by one down one right
    goto goright
  end
  else result:= location[1];
  //othersies return this location since this is where the bottle starts curving
  end
else
  begin
  while (pixelplus=pixel)and (uppixel=uppixelplus) do
  //as long as neither pixels on the right or below change
    begin
      location[0]:=location[0]+1; n:=n+1;//point location to right and add n
      //(number of steps required)
      pixelplus:=AMatrix[location[0]+1][location[1]];
      uppixel:=AMatrix[location[0]][location[1]-1];
      uppixelplus:=AMatrix[location[0]+1][location[1]-1];
      //re-record all pixel values
    end;
  setlength(storage,(length(storage)+1));
  storage[high(storage)]:=n;//of one of them breaks--add its steps n to storage
  if (pixelplus<>pixel) and (n>round(maxintvalue(storage)/2)) then
  //if an edge reached (going up )and there has been nosignificant
  //change in gradient
  begin
  location[0]:=location[0]+1; location[1]:=location[1]+1;
  n:=0; //reset n and shift position by one down one right
  goto goright;
  end
  else if (uppixelplus<>uppixel) and (n>round(maxintvalue(storage)/2)) then
  begin
    location[0]:=location[0]+1;location[1]:=location[1]-1;
    n:=0;//reset n and shift position by one up one right
    goto goright
  end
  else result:= location[1];
  //othersies return this location since this is where the bottle starts curving
  end;
end;
function Prediction
(firstedge,firstloc,secondedge,secondloc,thirdedge,thirdloc:integer
;radius,beta,alpha:single):integer;
//Maths block for contamination position prediction. Input the location of the
//lower boundary of the bottles and the location of contamination
var
a,b,c:integer;
begin

if (thirdloc=0) and (thirdedge=0)and (firstedge<>0) and (firstloc<>0) and
(secondedge<>0) and (secondloc<>0)  then
  begin
  a:=firstedge-firstloc;b:=secondedge-secondloc;
  result:=round(radius/sin(beta)-radius+b-tan(alpha)/tan(beta)*
  (a-radius/sin(alpha)+radius-b));
  end
else if (firstloc=0)and (firstedge=0) and (thirdloc<>0) and (thirdedge<>0)
and (secondedge<>0) and (secondloc<>0)  then
  begin
  a:=thirdedge-thirdloc;b:=secondedge-secondloc;
  result:=round(radius/sin(alpha)-radius+b-tan(beta)/tan(alpha)*
  (a-radius/sin(alpha)+radius-b));
  end
else if (secondloc=0)and(secondedge=0)and (thirdloc<>0) and (thirdedge<>0)
and (firstedge<>0) and (firstloc<>0) then
  begin
  a:= firstedge-firstloc;c:=thirdedge-thirdloc;
  result:=round(radius*2-((radius/(cos(beta)*(tan(beta)+tan(alpha))))+
  (1/(1+(tan(alpha)/tan(beta))))*(radius-c)
  -(1/(1+tan(beta)/tan(alpha)))*(a-radius-radius/sin(alpha))));
  end
else result:=0;

end;
function initialConditions(AMatrix:TPixelmatrix):integer;
//A function that produces automated thresholds th1 and th2
var
third,fourth,fifth: integer;
border1,border2,shiftup,shiftdown,pixel:integer;
shiftregister:array [0..1] of integer;
begin
shiftup:=0;shiftdown:=0;
third:=round(2/3*length(AMatrix[0]));
fourth:=third+round(1/4*third);
fifth:=fourth+round(1/5*fourth);
//three arbitary points of section for the image, this ensures the right
//hand side of the image's border is computed
th1:=fourth; //this seems reasonable for threshold 1
th2:=[42,95];//some random initialisation
//border1:= round((i+j+k)/3); border2:= round((a+b+c)/3);
border1:=borderControl(AMatrix,false); border2:=bordercontrol(AMatrix,true);
result:=border2; //in prediction function this value is needed
//obtain the edges of the base of the bottle
th2[0]:=round(2.5*border1);th2[1]:=border2-round(0.2*(length(AMatrix)-border2));
//seems reasonable for th2
//showmessage('th2='+inttostr(th2[0])+' '+inttostr(th2[1]));
//showmessage('th1='+inttostr(th1));
start[0]:=round(th1*1.1);start[1]:=round((border2-border1)/2+border1);

pixel:= AMatrix[start[0]][start[1]]; shiftregister[1]:=start[1];
shiftregister[0]:=start[0];
//coding for the case where contamination is right in the middle which will
//not be picked up by one search field
while pixel<>255 do
  begin
  shiftregister[0]:=shiftregister[0]+1;
  pixel:= AMatrix[shiftregister[0]][shiftregister[1]];
  end; //walk all the way down to an edge
while pixel<>0 do
  begin
  shiftregister[1]:=shiftregister[1]-1;
  shiftup:=shiftup+1;
  pixel:= AMatrix[shiftregister[0]][shiftregister[1]];
  end;
shiftregister[1]:=shiftregister[1]+shiftup;
pixel:= AMatrix[shiftregister[0]][shiftregister[1]];
while pixel<>0 do
  begin
  shiftregister[1]:=shiftregister[1]+1;
  shiftdown:=shiftdown+1;
  pixel:= AMatrix[shiftregister[0]][shiftregister[1]];
  end;
if (shiftup<4) or (shiftdown<4) then
  begin
  start[2]:=round(start[1]-4);
  start[3]:=round(start[1]+4);
  end
else if (shiftup>10) or (shiftdown>10) then
  begin
  start[2]:=round(start[1]-min(shiftup,shiftdown));
  start[3]:=round(start[1]+min(shiftup,shiftdown));
  end
else
  begin
  start[2]:=round(start[1]-shiftup);
  start[3]:=round(start[1]+shiftup);
  end;
start[0]:=shiftregister[0]-1;
//showmessage(inttostr(start[0])+' '+inttostr(start[1]));
end;
function bubblesort(AMatrix:TPixelmatrix):TPixelmatrix;
//Very crude bubblesort of O(n^2), okay for sorting out the cluster since
//the cluster is quiet small
var i,j,k,g:integer;
begin
for i := 0 to high(AMatrix) do
  begin
    for j := 0 to high(AMatrix)-1 do
    begin
      if AMatrix[j,1]<AMatrix[j+1,1] then
        begin
        k:=AMatrix[j,1];
        g:=AMatrix[j,0];
        AMatrix[j,1]:=AMatrix[j+1,1];
        AMatrix[j,0]:=AMatrix[j+1,0];
        AMatrix[j+1,1]:=k;
        AMatrix[j+1,0]:=g;
        end
      else if AMatrix[j,1]=AMatrix[j+1,1] then
        if AMatrix[j,0]<AMatrix[j+1,0] then
          begin
          k:=AMatrix[j,1];
          g:=AMatrix[j,0];
          AMatrix[j,1]:=AMatrix[j+1,1];
          AMatrix[j,0]:=AMatrix[j+1,0];
          AMatrix[j+1,1]:=k;
          AMatrix[j+1,0]:=g;
          end;
    end;
  end;
result:=AMatrix;
end;
function appendit(anArray:Tarray;number:integer):Tarray;
var
NoMatch:boolean; i:integer;
begin
NoMatch := true;
for i := Low(anArray) to High(anArray) do
if anArray[i] = number then
  begin
    NoMatch := false;
    break;
   end;
if NoMatch then
  begin
  setlength(anArray,(length(anArray)+1));
  anArray[high(anArray)]:=number;
  result:=anArray;
  end
else result:=anArray;
end;
function clusterAnalysis():Tarray;
var
Dictionary: TDictionary<smallint,Tarray>;
i: Integer;
anArray,removal:Tarray;
begin
anArray:=[];
dictionary:=TDictionary<smallint,Tarray>.create;
//dictionary.Add(97,[1,2,3,4]);
for i := 0 to length(clusters)-1 do
  begin
    if dictionary.ContainsKey(clusters[i][1])=true then
    anArray:=dictionary.Items[clusters[i][1]]
    else anArray:=0;
    anArray:=appendit(anArray,clusters[i][0]);
    dictionary.AddOrSetValue(clusters[i][1],anArray);
  end;
removal:=[];
for i in dictionary.keys do
  begin
  if length(dictionary.Items[i])<2 then
      begin
      removal:=appendit(removal,i);
      end;
  end;
for i in removal do
  begin
    dictionary.Remove(i);
  end;
dictionary.TrimExcess;
clusters:=[];
for i in dictionary.Keys do
  begin
  setlength(clusters,length(clusters)+1,2);
  clusters[high(clusters),0]:=i;
  clusters[high(clusters),1]:=length(dictionary.Items[i]);
  end;
clusters:=bubblesort(clusters);
end;
function clusterMean():Tarray;
var k,i:integer;std,mean:single;
begin
if length(clusters)<>0 then
  begin
  mean:=0;k:=0;
  for i := 0 to high(clusters) do
    begin
    k:=k+clusters[i,1];
    mean:=mean+clusters[i,0]*clusters[i,1]
    end;
  mean:=mean/k;
  i:=0;std:=0;
  for i := 0 to high(clusters) do
    begin
    std:=(std+sqr(clusters[i,0]-mean)*clusters[i,1]);
    end;
  std:=sqrt(std/k);
  setlength(result,2);
  result[0]:=round(mean); result[1]:=round(std);
  //showmessage(floattostr(mean))
  end
else exit;
end;
{procedure TForm1.binaryClick(Sender: TObject);
begin

if (length(pixelmatrix)=0) or (length(WorkingMatrix)=0) then
    begin
    showmessage('Input image empty or edge detection has not been performed');
    end
  else
    begin
      simpleBinary(WorkingMatrix);
      matrixtobitmap(WorkingMatrix);
      ShowPixelMatrix(memo1,WorkingMatrix);
    end;

end;
procedure TForm1.checkClick(Sender: TObject);
var S:string; input:Tarray;
begin
clusters:=[];stop:=false;
initialConditions(WorkingMatrix);
contaminentDetection(WorkingMatrix,[start[0],start[1]],true);
contaminentDetection(WorkingMatrix,[start[0],start[1]],false);
clusteranalysis();
showarray(memo1,clusters);
S:=' ';
setlength(input,2);
input:=clusterMean();
S:='Mean: '+floattostr(input[0])+', Standard Deviation: '+floattostr(input[1]);
form1.Memo1.Lines.Add(S);
end;
procedure TForm1.EdgeClick(Sender: TObject);

  begin
  if length(pixelmatrix)=0 then
    begin
    showmessage('Input Image Empty');
    end
  else
    begin
      edgedetection(WorkingMatrix);
      showpixelmatrix(memo1,pixelMatrix);
      matrixtobitmap(WorkingMatrix)
    end;

  end; }
function analyse(imageholder:integer):TArray;
var
 S:string; input:Tarray;
 i,k: Integer;
begin
  case imageholder of
    1: workingmatrix:=detector1Matrix;
    2: workingmatrix:=detector2Matrix;
    3: workingmatrix:=detector3Matrix;
  end;

  if (length(WorkingMatrix)=0) then exit
  //if the image input is empty then do nothing otherwise perform detection
  else
    begin
      edgedetection(WorkingMatrix);
      simpleBinary(WorkingMatrix);
      matrixtobitmap(WorkingMatrix,imageholder);
      //process the image and output it to its designated holder
      clusters:=[];stop:=false;
      k:=initialConditions(WorkingMatrix);
      //initialize clusters, stop switch for contaminent detection, thresholds
      //and the starting position
      for i := 1 to 3 do
      begin
      contaminentDetection(WorkingMatrix,[start[0],start[i]],true);
      contaminentDetection(WorkingMatrix,[start[0],start[i]],false);
      end;
      //repeat contaminent detection three times for accurate result and to
      //avoid landing on a contaminent as starting position
      clusteranalysis();
      //analyse the cluster
      showarray(form1.memo1,clusters,imageholder);
      setlength(input,2);
      input:=clusterMean();
      S:='Mean: '+floattostr(input[0])+', Standard Deviation: '+floattostr(input[1]);
      form1.Memo1.Lines.Add(S);
      //output results in memo
      setlength(result,4);
      result[0]:=imageholder;result[1]:=k;
      result[2]:=input[0];result[3]:=input[1];
      //store result dynamically [detectorNumber,mean,standardDeviation]
    end;

end;
function predictionResult(firstedge,firstloc,std1,secondedge,
             secondloc,std2,thirdedge,thirdloc,std3:integer):TArray;
var
k,i,j,inter:integer; answer:TArray; S:string;
begin
for i := 0 to std1 do
  for j := 0 to std2 do
    for k := 0 to std3 do
      begin
        inter:=prediction(firstedge,firstloc+i,secondedge,secondloc+j,thirdedge,thirdloc+k,44.9,0.79,0.82);
        if inter<>0 then
          begin
          setlength(answer,length(answer)+1);
          answer[high(answer)]:=inter;
          end;
        if firstloc-i<0 then firstloc:=firstloc+i;
        if secondloc-j<0 then secondloc:=secondloc+j;
        if thirdloc-k<0 then thirdloc:=thirdloc+k;
        inter:=prediction(firstedge,firstloc-i,secondedge,secondloc-j,thirdedge,thirdloc-k,44.9,0.79,0.82);
        if inter<>0 then
          begin
          setlength(answer,length(answer)+1);
          answer[high(answer)]:=inter;
          end;
      end;
if length(answer)<>0 then
  begin
    for i := 0 to high(answer) do
      begin
        setlength(result,length(result)+1);
        result[(high(result))]:=answer[i];
      end;
  end;

end;
function RunPrediction():boolean;
var
i,j:integer;
k:TArray; three,two,one,three1,two1,one1:TArray;
firstedge,firstloc,secondedge,
secondloc,thirdedge,thirdloc,std1,std2,std3:integer;
calculationInput:TPixelmatrix;S:string;
begin
for i := 1 to 3 do
 begin
 k:=[];
 k:=analyse(i);
 setlength(calculationInput,length(calculationInput)+1,4);
 if length(k)<>0 then
  begin
  for j := 0 to 3 do calculationInput[high(calculationInput)][j]:=k[j];
  end
 else
  begin
  calculationInput[high(calculationInput)][0]:=i;
  end;
 end;
//run analyse function which prepares all the calculation inputs
//In the following format:
//CalculationInput[[ImageLocaion,ImageBottomBorder,ContaminentLoc,STD],...]
firstedge:=calculationInput[0][1];firstloc:=calculationInput[0][2];
secondedge:=calculationInput[1][1];secondloc:=calculationInput[1][2];
thirdedge:=calculationInput[2][1];thirdloc:=calculationInput[2][2];
std1:=calculationInput[0][3];std2:=calculationInput[1][3];
std3:=calculationInput[2][3];
S:='Contamination prediction FOR detector 3:';
form1.Memo1.Lines.Add(S);
three:=predictionresult(firstedge,firstloc,std1,secondedge,secondloc,std2,0,0,std3);
if length(three)<>0 then
  begin
  setlength(three1,2);three1[0]:=thirdedge-MinIntValue(three);
  three1[1]:=thirdedge-MaxIntValue(three);
  S:='('+inttostr(three1[0])+','+inttostr(three1[1])+')';
  form1.Memo1.Lines.Add(S);
  end
else form1.Memo1.Lines.Add('Nil');

S:='Contamination prediction FOR detector 2:';
form1.Memo1.Lines.Add(S);
two:=predictionresult(firstedge,firstloc,std1,0,0,std2,thirdedge,thirdloc,std3);
if length(two)<>0 then
  begin
  setlength(two1,2);two1[0]:=secondedge-MinIntValue(two);
  two1[1]:=secondedge-MaxIntValue(two);
  S:='('+inttostr(two1[0])+','+inttostr(two1[1])+')';
  form1.Memo1.Lines.Add(S);
  end
else form1.Memo1.Lines.Add('Nil');

S:='Contamination prediction FOR detector 1:';
form1.Memo1.Lines.Add(S);
one:=predictionresult(0,0,std1,secondedge,secondloc,std2,thirdedge,thirdloc,std3);
if length(one)<>0 then
  begin
  setlength(one1,2);one1[0]:=firstedge-MinIntValue(one);
  one1[1]:=firstedge-MaxIntValue(one);
  S:='('+inttostr(one1[0])+','+inttostr(one1[1])+')';
  form1.Memo1.Lines.Add(S);
  end
else form1.Memo1.Lines.Add('Nil');

end;

procedure TForm1.load1Click(Sender: TObject);

var
  Bitmap: TBitmap;
  PixelMatrix: TPixelMatrix;

begin
  if OpenPictureDialog1.Execute=true then
    detector1IN.Picture.LoadFromFile(openpicturedialog1.FileName);
    begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.LoadFromFile(openpicturedialog1.FileName);
      PixelMatrix:=BitmapToMatrix(Bitmap, PixelMatrix);
      detector1Matrix:=pixelmatrix;
    finally
      Bitmap.Free;
    end;
  end;
end;
procedure TForm1.load2Click(Sender: TObject);
var
  Bitmap: TBitmap;
  PixelMatrix: TPixelMatrix;
begin
  if OpenPictureDialog2.Execute then
    detector2IN.Picture.LoadFromFile(openpicturedialog2.FileName);
    begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.LoadFromFile(openpicturedialog2.FileName);
      BitmapToMatrix(Bitmap, PixelMatrix);
      detector2Matrix:=pixelmatrix;
    finally
      Bitmap.Free;
    end;
  end;
end;
procedure TForm1.load3Click(Sender: TObject);
var
  Bitmap: TBitmap;
  PixelMatrix: TPixelMatrix;
begin
  if OpenPictureDialog3.Execute then
    detector3IN.Picture.LoadFromFile(openpicturedialog3.FileName);
    begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.LoadFromFile(openpicturedialog3.FileName);
      BitmapToMatrix(Bitmap, PixelMatrix);
      detector3Matrix:=pixelmatrix;
    finally
      Bitmap.Free;
    end;
  end;
end;
procedure TForm1.magic1Click(Sender: TObject);
var
starttime64,endtime64,frequency64:int64;
time:single; S:string;
begin
memo1.Clear;
queryperformancefrequency(frequency64);
queryperformancecounter(starttime64);
//initialize timer
runprediction();
queryperformancecounter(endtime64);
time:=(endtime64-starttime64)*1000/frequency64;
 //end the timer and convert
form1.Memo1.Lines.Add(S);
S:='Time elapsed: '+floattostr(roundto(time,-2))+' ms';
form1.Memo1.Lines.Add(S);//output all results collected

end;
end.
