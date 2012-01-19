#import('dart:html');
#source('Terminal.dart');

class TerminalExample {

  TerminalExample() {
    Terminal t = new Terminal('#input-line', '#output', '#cmdline');
  }

  void run() {
    //write("Hello World!");
    //var cmdLine = document.query('#')
  }

  void write(String message) {
    // the HTML library defines a global "document" variable
    //document.query('#status').innerHTML = message;
  }
}

void main() {
  new TerminalExample().run();
}
