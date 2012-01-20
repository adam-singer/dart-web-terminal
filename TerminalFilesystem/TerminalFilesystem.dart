#import('dart:core');
#import('dart:html');
//#import('dart:dom', prefix:"dom");
//#import('dart:htmlimpl', prefix:"htmlimpl");
#source('Terminal.dart');
// #source('Commands.dart');
class TerminalFilesystem {

  TerminalFilesystem() {
  }

  void run() {
    Terminal t = new Terminal('#input-line', '#output', '#cmdline');
    
  }
}

void main() {
  new TerminalFilesystem().run();
}
