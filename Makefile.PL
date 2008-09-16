use inc::Module::Install;
name 'WebService-Hatena-Diary';
all_from 'lib/WebService/Hatena/Diary.pm';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
