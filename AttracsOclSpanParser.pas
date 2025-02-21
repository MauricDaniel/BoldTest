unit AttracsOclSpanParser;

interface

uses
  // VCL
  Classes,
  Contnrs,

  // Bold
  BoldBase,
  BoldSystemRt,
  BoldOcl,
  BoldOclClasses,
  BoldElements,
  SpanDefinition,
  AbstractSpanParser;

type
  TSpanArrayNamedCollection = class;
  TSpanArray = array of TBoldObjectSpan;

  TAttracsOclSpanParser = class(TAbstractSpanParser)
  private
    fEvaluator: TBoldOcl;
    fContextualVariableStack: TSpanArrayNamedCollection;
    fGlobalVariableStack : TSpanArrayNamedCollection;
    fCurrentContextSpans: TSpanArray;

    function DoParse(const Expression: String; Evaluator: TBoldOcl; ContextType: TBoldClassTypeinfo; VariableList: TBoldExternalVariableList = nil): TBoldSpan;
    function TranslateOclOperation(OclOperation: TBoldOclOperation): TSpanArray;
    function TranslateOclListCoercion(OclListCoercion: TBoldOclListCoercion): TSpanArray;
    function TranslateOclIteration(OclIteration: TBoldOclIteration): TSpanArray;
    function TranslateOclMember(OclMember: TBoldOclMember): TSpanArray;
    function TranslateOclVariableReference(OclVariableReference: TBoldOclVariableReference): TSpanArray;
    function TranslateEntry(oclNode: TBoldOclNode): TSpanArray;
  protected
    function GetTypeSystem: TBoldSystemTypeInfo;
    property TypeSystem: TBoldSystemTypeInfo read GetTypeSystem;
  public
    constructor Create;
    destructor Destroy; override;
    class function Parse(const Expression: String; ContextType: TBoldClassTypeinfo;

      VariableList: TBoldExternalVariableList = nil; Evaluator: TBoldOcl = nil): TBoldSpan; override;
  end;

  TSpanArrayNamedCollectionEntry = class
  private
    fName: string;
    fSpanArray:TSpanArray;
  public
    constructor Create(const Name: string; const Span: TSpanArray);
    destructor Destroy; override;
    property Name: string read fName;
    property SpanArray: TSpanArray read fSpanArray;
  end;

  TSpanArrayNamedCollection = class
    fStack: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PushDefinition(const name: string; const Spans:TSpanArray);
    procedure PopDefinition;
    function Lookup(const name: string): TSpanArray;
  end;

implementation

uses
{$IFDEF FINDCORRUPTIONBUG}
  FastMM4,
{$ENDIF}
  SysUtils,
  BoldUtils,
{$IFDEF Attracs}
  AttracsErrorMgr,
{$ENDIF}
  BoldSystem;

constructor TAttracsOclSpanParser.Create;
begin
  fContextualVariableStack := TSpanArrayNamedCollection.Create;
  fGlobalVariableStack := TSpanArrayNamedCollection.Create;
end;

destructor TAttracsOclSpanParser.Destroy;
begin
  FreeAndNil(fContextualVariableStack);
  FreeAndNil(fGlobalVariableStack);
  inherited;
end;

function TAttracsOclSpanParser.DoParse(const Expression: String; Evaluator: TBoldOcl;
  ContextType: TBoldClassTypeinfo; VariableList: TBoldExternalVariableList = nil): TBoldSpan;
var
  ResultEntry: TBoldOclEntry;
begin
  ResultEntry := Evaluator.SemanticCheck(Expression, ContextType, VariableList);
  Result := TBoldSpan.Create(ContextType);
  SetLength(fCurrentContextSpans, 1);
  fCurrentContextSpans[0] := result;
  try
    fContextualVariableStack.PushDefinition('self',  fCurrentContextSpans);
    if Assigned(ResultEntry) then
      TranslateEntry(ResultEntry.Ocl);
  finally
    Evaluator.DoneWithEntry(ResultEntry);
  end;
end;

function TAttracsOclSpanParser.GetTypeSystem: TBoldSystemTypeInfo;
begin
  result := fEvaluator.BoldSystem.BoldSystemTypeInfo;
end;

class function TAttracsOclSpanParser.Parse(const Expression: String; ContextType: TBoldClassTypeinfo;
  VariableList: TBoldExternalVariableList = nil; Evaluator: TBoldOcl = nil): TBoldSpan;
var
  Parser: TAttracsOclSpanParser;
begin
{$IFDEF FINDCORRUPTIONBUG}
  ScanMemoryPoolForCorruptions;
{$ENDIF}
  Parser := TAttracsOclSpanParser.Create;
  try
    if not Assigned(Evaluator) then
      Evaluator := TBoldSystem.DefaultSystem.Evaluator as TBoldOcl;
    Parser.fEvaluator := Evaluator;
    Result := Parser.DoParse(Expression, Evaluator, ContextType, VariableList);
  finally
    Parser.Free;
  end;
end;

function TAttracsOclSpanParser.TranslateEntry( oclNode: TBoldOclNode): TSpanArray;
begin
  if oclNode is TBoldOclVariableReference then
    Result := TranslateOclVariableReference(OclNode as TBoldOclVariableReference)
  else if oclNode is TBoldOclMember then
    Result := TranslateOclMember(OclNode as TBoldOclMember)
  else if oclNode is TBoldOclIteration then
    Result := TranslateOclIteration(OclNode as TBoldOclIteration)
  else if oclNode is TBoldOclMethod then
    raise ESpanException.Create('Can''t autotranslate Method calls:' + (oclNode as TBoldOclMethod).OperationName)
  else if oclNode is TBoldOclOperation then
    Result := TranslateOclOperation(OclNode as TBoldOclOperation)
  else if oclNode is TBoldOclListCoercion then
    Result := TranslateOclListCoercion (OclNode as TBoldOclListCoercion)
  else if oclNode is TBoldOclStrLiteral then
    Result := nil
  else if oclNode is TBoldOclLiteral then
    Result := nil
  else if oclNode is TBoldOclTypeNode then
    Result := nil
  else
    raise ESpanException.Create('Can''t autotranslate nodetype: ' + oclNode.ClassName);
end;

function TAttracsOclSpanParser.TranslateOclIteration(OclIteration: TBoldOclIteration): TSpanArray;
var
  OldContext: TSpanArray;
  Arg1result: TSpanArray;
begin
  OldContext := fCurrentContextSpans;
  fCurrentContextSpans := TranslateEntry(OclIteration.Args[0]);
  fContextualVariableStack.PushDefinition(OclIteration.LoopVar.VariableName, fCurrentContextSpans);
  Arg1result := TranslateEntry(OclIteration.Args[1]);
  fContextualVariableStack.PopDefinition;
  if BoldNamesEqual(OclIteration.OperationName, 'collect') then
    Result :=  Arg1result
  else
    Result := fCurrentContextSpans;
  fCurrentContextSpans := OldContext;
end;

function TAttracsOclSpanParser.TranslateOclListCoercion(
  OclListCoercion: TBoldOclListCoercion): TSpanArray;
begin
   Result := TranslateEntry(OclListCoercion.Child);
end;

function TAttracsOclSpanParser.TranslateOclMember(OclMember: TBoldOclMember): TSpanArray;
var
  MemberOfSpans: TSpanArray;
  attributeNode: TBoldAttributeNode;              // PALOFF MEMO4
  roleNode: TBoldRoleNode;                        // PALOFF MEMO4
  i: integer;
begin
  MemberOfSpans := TranslateEntry(OclMember.MemberOf);
  if not Assigned(MemberOfSpans) then
     raise ESpanException.Create(Format('%s seems not to be a member of anything', [OclMember.RTInfo.ExpressionName]));

  if OclMember.RtInfo.IsAttribute then
  begin
    for i := 0 to Length(MemberOfSpans)-1  do
      begin
        attributeNode := TBoldAttributeNode.Create(Oclmember.RtInfo as TBoldAttributeRTInfo);
        MemberOfSpans[i].AddSubnode(attributeNode);
      end;
  Result := nil;
  end
  else //OclMember is TBoldRole
  begin
    SetLength(Result, Length(MemberOfSpans));
    for i := 0 to Length(MemberOfSpans)-1  do
    begin
      roleNode := TBoldRoleNode.Create(Oclmember.RtInfo as TBoldRoleRTInfo);
      roleNode.FetchDefaultMembers := true;
      MemberOfSpans[i].AddSubnode(roleNode);
      Result[i] := RoleNode;
    end;
  end
end;

function Union(const Part1, Part2: TSpanArray): TSpanArray;
var
  Length1, Length2, i: integer;
begin
  Length1 := Length(Part1);
  Length2 := Length(Part2);
  SetLength(Result, Length1 + Length2);
  for I := 0 to Length1 - 1 do
    Result[i] := Part1[i];
  for I := 0 to Length2 - 1 do
    Result[I + Length1] := Part2[i];
end;

function TAttracsOclSpanParser.TranslateOclOperation(OclOperation: TBoldOclOperation): TSpanArray;
var
  Arg0Value: TSpanArray;
  OperationName: string;
  ClassTypeInfo: TBoldClassTypeInfo;
  ClassFilterNode: TBoldClassFilterNode;                // PALOFF MEMO4
  AllInstancesNode: TBoldAllInstancesNode;              // PALOFF MEMO4
  asStringNode: TBoldAsStringNode;                      // PALOFF MEMO4
  TypeName: string;
  i: integer;
begin
  OperationName := OclOperation.OperationName;
  if BoldNamesEqual(OperationName, 'if') then
  begin
    TranslateEntry(OclOperation.Args[0]);
    Result := Union(TranslateEntry(OclOperation.Args[1]), TranslateEntry(OclOperation.Args[2]));
   end
  else if BoldNamesEqual(OperationName, 'first') or
    BoldNamesEqual(OperationName, 'last')
  then
  begin
    Result := TranslateEntry(OclOperation.Args[0]);
  end
  else if BoldNamesEqual(OperationName, 'at')
  then
  begin
    Result := TranslateEntry(OclOperation.Args[0]);
    TranslateEntry(OclOperation.Args[1]);
  end // no parameters, non result
  else if
    BoldNamesEqual(OperationName, 'emptyList') or
    BoldNamesEqual(OperationName, 'nullValue') or
    BoldNamesEqual(OperationName, 'boldTime')
    then
    begin
      Result := nil;
    end
  else if // one parameter, no result
    BoldNamesEqual(OperationName, 'not') or
    BoldNamesEqual(OperationName, 'oclIsTypeOf') or
    BoldNamesEqual(OperationName, 'oclType') or
    BoldNamesEqual(OperationName, 'asDateTime') or
    BoldNamesEqual(OperationName, 'count') or
    BoldNamesEqual(OperationName, 'size') or
    BoldNamesEqual(OperationName, 'sum') or
    BoldNamesEqual(OperationName, 'isEmpty') or
    BoldNamesEqual(OperationName, 'notEmpty') or
    BoldNamesEqual(OperationName, 'isNull') or
    BoldNamesEqual(OperationName, 'formatDateTime') or
    BoldNamesEqual(OperationName, 'length') or
    BoldNamesEqual(OperationName, 'unary-') or
    BoldNamesEqual(OperationName, 'abs') or
    BoldNamesEqual(OperationName, 'floor') or
    BoldNamesEqual(OperationName, 'round') or
    BoldNamesEqual(OperationName, 'simpleRound') or
	BoldNamesEqual(OperationName, 'simpleRoundTo') or    
    BoldNamesEqual(OperationName, 'strToInt') or
    BoldNamesEqual(OperationName, 'strToFloat') or    
    BoldNamesEqual(OperationName, 'toUpper') or
    BoldNamesEqual(OperationName, 'toLower') or
    BoldNamesEqual(OperationName, 'strToDate') or
    BoldNamesEqual(OperationName, 'strToTime') or
    BoldNamesEqual(OperationName, 'strToDateTime') or
    BoldNamesEqual(OperationName, 'asFloat') or
    BoldNamesEqual(OperationName, 'datePart') or
    BoldNamesEqual(OperationName, 'oclIsKindOf') or
    BoldNamesEqual(OperationName, 'formatDateTime') or
    BoldNamesEqual(OperationName, 'asCommaText') or
    BoldNamesEqual(OperationName, 'separate') or
    BoldNamesEqual(OperationName, 'day') or
    BoldNamesEqual(OperationName, 'month') or
    BoldNamesEqual(OperationName, 'year') or
    BoldNamesEqual(OperationName, 'dayOfWeek') or
    BoldNamesEqual(OperationName, 'asISODateTime') or
    BoldNamesEqual(OperationName, 'asISODate') or
    BoldNamesEqual(OperationName, 'week') or
    BoldNamesEqual(OperationName, 'formatNumeric') or
    BoldNamesEqual(OperationName, 'maxValue') or
    BoldNamesEqual(OperationName, 'minValue') or
    BoldNamesEqual(OperationName, 'constraints') or
    BoldNamesEqual(OperationName, 'floatAsDateTime') or
    BoldNamesEqual(OperationName, 'trim') or
    BoldNamesEqual(OperationName, 'average') or
    BoldNamesEqual(OperationName, 'hasDuplicates') or
    BoldNamesEqual(OperationName, 'allSubClasses') or
    BoldNamesEqual(OperationName, 'toStringCollection') or
    BoldNamesEqual(OperationName, 'toIntegerCollection') or
    BoldNamesEqual(OperationName, 'stringRepresentation') or
    BoldNamesEqual(OperationName, 'boldId') or
    BoldNamesEqual(OperationName, 'sqrt')
    then
  begin
    TranslateEntry(OclOperation.Args[0]);
    Result := nil;
  end
  else if BoldNamesEqual(OperationName, 'asString')  then
  begin
    Arg0Value := TranslateEntry(OclOperation.Args[0]);
    for I := 0 to Length(Arg0Value) - 1 do
    begin
       asStringNode := TBoldAsStringNode.Create(Arg0Value[i].UmlClass);
       Arg0Value[i].AddSubNode(asStringNode);
    end;
  Result := nil;
  end
  else if // two parameters, no result
    (OperationName = '<>') or
    (OperationName = '=') or
    (OperationName = '<') or
    (OperationName = '>') or
    (OperationName = '<=') or
    (OperationName = '>=') or
    (OperationName = '+') or
    (OperationName = '-') or
    (OperationName = '*') or
    (OperationName = '/') or
    BoldNamesEqual(OperationName, 'concat') or
    BoldNamesEqual(OperationName, 'and') or
    BoldNamesEqual(OperationName, 'or') or
    BoldNamesEqual(OperationName, 'min') or
    BoldNamesEqual(OperationName, 'max') or
    BoldNamesEqual(OperationName, 'mod') or    
    BoldNamesEqual(OperationName, 'like') or
    BoldNamesEqual(OperationName, 'sqlLike') or
    BoldNamesEqual(OperationName, 'sqlLikeCaseInsensitive') or
    BoldNamesEqual(OperationName, 'regExpMatch') or
    BoldNamesEqual(OperationName, 'includes') or
    BoldNamesEqual(OperationName, 'contains') or
    BoldNamesEqual(OperationName, 'indexOf') or
    BoldNamesEqual(OperationName, 'safeDiv') or
    BoldNamesEqual(OperationName, 'hoursBetween') or
    BoldNamesEqual(OperationName, 'minutesBetween') or
    BoldNamesEqual(OperationName, 'secondsBetween') or
    BoldNamesEqual(OperationName, 'power') or
    BoldNamesEqual(OperationName, 'boldIDIn') or
    BoldNamesEqual(OperationName, 'namedIDIn') then
  begin
    TranslateEntry(OclOperation.Args[0]);
    TranslateEntry(OclOperation.Args[1]);
    Result := nil;
  end
  else if // three parameters, no result
    BoldNamesEqual(OperationName, 'subString') or
    BoldNamesEqual(OperationName,'inDateRange') or
    BoldNamesEqual(OperationName, 'inTimeRange')
  then
  begin
    TranslateEntry(OclOperation.Args[0]);
    TranslateEntry(OclOperation.Args[1]);
    TranslateEntry(OclOperation.Args[2]);
    Result := nil;
  end
  else if // one parameter, which is result
    BoldNamesEqual(OperationName, 'reverseCollection') or
    BoldNamesEqual(OperationName, 'asSet') or
    BoldNamesEqual(OperationName, 'orderby') or
    BoldNamesEqual(OperationName, 'subSequence') or    
    BoldNamesEqual(OperationName, 'orderdescending')
  then
  begin
    Result := TranslateEntry(OclOperation.Args[0]);
  end
  else if
    BoldNamesEqual(OperationName, 'safecast') or
    BoldNamesEqual(OperationName, 'oclAsType') or
    BoldNamesEqual(OperationName, 'filterOnType')
  then
  begin
    typeName := (OclOperation.Args[1] as TBoldOclTypeNode).typeName;
    ClassTypeInfo := TypeSystem.ClassTypeInfoByExpressionName[typeName];
    Arg0Value := TranslateEntry(OclOperation.Args[0]);
    SetLength(Result, Length(Arg0Value));

    for I := 0 to Length(Arg0Value) - 1 do
    begin
       ClassFilterNode := TBoldClassFilterNode.Create(ClassTypeInfo);
       Arg0Value[i].AddSubNode(ClassFilterNode);
       Result[i] := ClassFilterNode;
    end;
  end                                                             
  else if
    BoldNamesEqual(OperationName, 'allinstances') or
    BoldNamesEqual(OperationName, 'allLoadedObjects')
  then
  begin
    typeName := (OclOperation.Args[0] as TBoldOclTypeNode).typeName;
    ClassTypeInfo := TypeSystem.ClassTypeInfoByExpressionName[typeName];
    if Assigned(ClassTypeInfo) then // ClassTypeInfo is nil with Enumerated types (like Weekday.allInstances)
    begin
      SetLength(Result, Length(fCurrentContextSpans));
      for I := 0 to Length(fCurrentContextSpans) - 1 do
      begin
        AllInstancesNode := TBoldAllInstancesNode.Create(ClassTypeInfo, BoldNamesEqual(OperationName, 'allLoadedObjects'));
        fCurrentContextSpans[i].AddSubNode(AllInstancesNode);
        Result[i] := AllInstancesNode;
      end;
    end
    else
      Result := nil;
  end
  else if BoldNamesEqual(OperationName, 'union') or
    BoldNamesEqual(OperationName, 'symmetricDifference') or
    BoldNamesEqual(OperationName, 'includesAll') or
    BoldNamesEqual(OperationName, 'intersection') or
    BoldNamesEqual(OperationName, 'including') or
    BoldNamesEqual(OperationName, 'excluding') or
    BoldNamesEqual(OperationName, 'difference')
  then
  begin
    Result := Union(TranslateEntry(OclOperation.Args[0]), TranslateEntry(OclOperation.Args[1]));
  end
  else
    raise ESpanException.Create('Can''t autotranslate operation:' + OclOperation.OperationName);
end;

function TAttracsOclSpanParser.TranslateOclVariableReference(
  OclVariableReference: TBoldOclVariableReference): TSpanArray;
var
  VariableName: string;
begin
  VariableName := OclVariableReference.VariableName;
  if BoldNamesEqual(VariableName, 'true')
    or BoldNamesEqual(VariableName, 'false')
    or BoldNamesEqual(VariableName, 'nil')
    or not (OclVariableReference.BoldType is TBoldClassTypeInfo)
  then
    Result := nil
  else
  begin
    Result := fContextualVariableStack.Lookup(VariableName);
    if Result = nil then
    begin
      Result := fGlobalVariableStack.Lookup(VariableName);
      if (Result=nil) and (OclVariableReference.BoldType is TBoldClassTypeInfo) then
      begin
          SetLength(Result, 1);
          Result[0] := TBoldSpan.Create(OclVariableReference.BoldType as TBoldClassTypeInfo);
          fGlobalVariableStack.PushDefinition(VariableName,Result);
      end;
    end
  end;
end;

{ TSpanArrayNamedCollectionEntry }

constructor TSpanArrayNamedCollectionEntry.Create(const Name: string; const Span: TSpanArray);
begin
  fName := Name;
  fSpanArray := Span;
end;

destructor TSpanArrayNamedCollectionEntry.Destroy;
begin
  inherited;
end;

{ TSpanArrayNamedCollection }

constructor TSpanArrayNamedCollection.Create;
begin
  fStack := TObjectList.Create;
end;

destructor TSpanArrayNamedCollection.Destroy;
begin
  FreeAndNil(fStack);
  inherited;
end;

function TSpanArrayNamedCollection.Lookup(const Name: string): TSpanArray;
var
  i: Integer;
  Entry: TSpanArrayNamedCollectionEntry;
begin
  Result := nil;
  for I := fStack.Count - 1 downto 0 do
  begin
    Entry := fStack[i] as TSpanArrayNamedCollectionEntry;
    if BoldNamesEqual(Entry.Name, Name)  then
    begin
      Result := Entry.SpanArray;
      Exit;
    end;
  end;
end;

procedure TSpanArrayNamedCollection.PopDefinition;
begin
  fStack.Delete(fStack.Count-1);
end;

procedure TSpanArrayNamedCollection.PushDefinition(const name: string; const Spans: TSpanArray);
begin
  fStack.Add(TSpanArrayNamedCollectionEntry.Create(Name, Spans));
end;

end.
