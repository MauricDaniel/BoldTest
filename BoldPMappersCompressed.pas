{ Global compiler directives }
{$include bold.inc}
unit BoldPMappersCompressed;

interface

uses
  BoldMemberTypeDictionary,
  BoldDefs,
  BoldPMappersAttributeDefault,
  BoldId,
  BoldValueSpaceInterfaces,
  BoldDBInterfaces;

type
  TBoldPMCompressedString = class(TBoldPMString)
  public
    procedure ValueFromField(OwningObjectId: TBoldObjectId; const ObjectContent: IBoldObjectContents; const ValueSpace: IBoldValueSpace; TranslationList: TBoldIdTranslationList; const Field: IBoldField; ColumnIndex: Integer); override;
    procedure ValueToParam(const ObjectContent: IBoldObjectContents; const Param: IBoldParameter; ColumnIndex: Integer; TranslationList: TBoldIdTranslationList); override;
  end;

  TBoldPMCompressedBlob = class(TBoldPMBlob)
    procedure ValueFromField(OwningObjectId: TBoldObjectId; const ObjectContent: IBoldObjectContents; const ValueSpace: IBoldValueSpace; TranslationList: TBoldIdTranslationList; const Field: IBoldField; ColumnIndex: Integer); override;
    procedure ValueToParam(const ObjectContent: IBoldObjectContents; const Param: IBoldParameter; ColumnIndex: Integer; TranslationList: TBoldIdTranslationList); override;
  end;

implementation

uses
  Classes,
  SysUtils,
  BoldValueInterfaces,
  BoldPMapperLists,
  BoldDefaultStreamNames,
  ZLibEx;

const
  cMinCompressedLength = 8;

{ TBoldPMCompressedString }

procedure TBoldPMCompressedString.ValueFromField(OwningObjectId: TBoldObjectId;
  const ObjectContent: IBoldObjectContents; const ValueSpace: IBoldValueSpace;
  TranslationList: TBoldIdTranslationList; const Field: IBoldField;
  ColumnIndex: Integer);
var
  s: TBoldAnsiString;
const
  cHeader = 'xœ';
begin
  if Field.IsNull then
    inherited;
  EnsureFirstColumn(ColumnIndex);
  s := Field.AsAnsiString;
  if (s <> '') and (length(s) >= cMinCompressedLength) then
  try
    if copy(s,1,length(cHeader)) = cHeader then
    s := ZLibEx.ZDecompressStr(s);
  except
    on e:EZDecompressionError do;
    // we ignore Decompress errors, this can happen when reading existing uncompressed data
    else raise;
  end;
  (GetEnsuredValue(ObjectContent) as IBoldStringContent).AsString := string(s);
end;

procedure TBoldPMCompressedString.ValueToParam(
  const ObjectContent: IBoldObjectContents; const Param: IBoldParameter;
  ColumnIndex: Integer; TranslationList: TBoldIdTranslationList);
var
  vValue: IBoldNullableValue;
  s: string;
begin
  EnsureFirstColumn(ColumnIndex);
  vValue := GetEnsuredValue(ObjectContent) as IBoldNullableValue;
  if vValue.IsNull then
    SetParamToNullWithDataType(Param, GetColumnBDEFieldType(0))
  else
  begin
    Param.DataType := ColumnBDEFieldType[ColumnIndex];
    s :=  (vValue as IBoldStringContent).AsString;
// commented out compression when writing to db, needed for Postgres
//    if s <> '' then
//      s := ZLibEx.ZCompressStr(s);
    Param.AsString := s;
  end;
end;

{ TBoldPMCompressedBlob }

procedure TBoldPMCompressedBlob.ValueFromField(OwningObjectId: TBoldObjectId;
  const ObjectContent: IBoldObjectContents; const ValueSpace: IBoldValueSpace;
  TranslationList: TBoldIdTranslationList; const Field: IBoldField;
  ColumnIndex: Integer);
var
  b: TBytes;
  s, d: TBytesStream;
begin
  if Field.IsNull then
    inherited;
  EnsureFirstColumn(ColumnIndex);
  b := Field.AsBytes;
  if length(b) > cMinCompressedLength then
  begin
    s := TBytesStream.Create(b);
    d := TBytesStream.Create;
    try
      try
        ZLibEx.ZDecompressStream(s, d);
       (GetEnsuredValue(ObjectContent) as IBoldBlobContent).AsBytes := d.Bytes;
      except
        on EZDecompressionError do
        // we ignore Decompress errors, this can happen when reading existing uncompressed data
        else
        raise;
      end;
    finally
      s.Free;
      d.Free;
    end;
  end
  else
    (GetEnsuredValue(ObjectContent) as IBoldBlobContent).AsBytes := b;
end;

procedure TBoldPMCompressedBlob.ValueToParam(const ObjectContent: IBoldObjectContents;
  const Param: IBoldParameter; ColumnIndex: Integer;
  TranslationList: TBoldIdTranslationList);
var
  vValue: IBoldNullableValue;
  b: TBytes;
  s, d: TBytesStream;
begin
  EnsureFirstColumn(ColumnIndex);
  vValue := GetEnsuredValue(ObjectContent) as IBoldNullableValue;
  if vValue.IsNull then
    SetParamToNullWithDataType(Param, GetColumnBDEFieldType(0))
  else
  begin
    Param.DataType := ColumnBDEFieldType[ColumnIndex];
    b := (vValue as IBoldBlobContent).AsBytes;
    Assert(Length(b) > 0); // length 0 should be same as isNull
    s := TBytesStream.Create(b);
    d := TBytesStream.Create;
    try
      ZLibEx.ZCompressStream(s,d);
      Param.AsBlob := d.Bytes;
    finally
      s.Free;
      d.Free;
    end;
  end;
end;


initialization
  BoldMemberPersistenceMappers.AddDescriptor(TBoldPMCompressedString, alConcrete);
  BoldMemberPersistenceMappers.AddDescriptor(TBoldPMCompressedBlob, alConcrete);

finalization
  if BoldMemberPersistenceMappersAssigned and BoldMemberTypesAssigned then
  begin
    BoldMemberPersistenceMappers.RemoveDescriptorByClass(TBoldPMCompressedString);
    BoldMemberPersistenceMappers.RemoveDescriptorByClass(TBoldPMCompressedBlob);
  end;

end.
