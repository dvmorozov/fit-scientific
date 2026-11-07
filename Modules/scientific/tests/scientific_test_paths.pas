// SPDX-License-Identifier: GPL-3.0-or-later
{
@abstract(Where the scientific module's own files are, seen from a suite's binary.)

Every suite that links this module's tests - the framework's, Fit Pro's - is
built into fit/tests, and the module is the repository fit-scientific beside
fit, so its samples and fixtures are two folders up from the running binary and
one over. Written once here instead of in each test that reads one of them: the
paths were a copy in six places while the module was inside the framework tree,
and moving the module was a six-place edit.
}
unit scientific_test_paths;

{$mode objfpc}{$H+}

interface

{ The module's repository, with a trailing separator. }
function ScientificRepoDir: string;

{ The diffraction samples (1.dat to 9.dat), with a trailing separator. }
function ScientificSampleDir: string;

{ A file of the module's own, named from its repository's root with forward
  slashes: ScientificFile('Modules/scientific/tests/fixtures/x.xrdml'). }
function ScientificFile(const ARelative: string): string;

implementation

uses
    SysUtils;

function ScientificRepoDir: string;
begin
    Result := IncludeTrailingPathDelimiter(ExpandFileName(
        ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + '..' +
        DirectorySeparator + 'fit-scientific'));
end;

function ScientificSampleDir: string;
begin
    Result := ScientificRepoDir + 'Data' + DirectorySeparator;
end;

function ScientificFile(const ARelative: string): string;
begin
    Result := ScientificRepoDir + StringReplace(ARelative, '/',
        DirectorySeparator, [rfReplaceAll]);
end;

end.
