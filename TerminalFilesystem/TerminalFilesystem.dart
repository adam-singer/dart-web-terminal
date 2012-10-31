#import('dart:core');
#import('dart:html');
#source('Terminal.dart');

class TerminalFilesystem {
  Terminal term;
  TerminalFilesystem() {
  }

  void run() {
    term = new Terminal('#input-line', '#output', '#cmdline');
    term.initFS(false, 1024 * 1024);
    
    print('window.location.hash = ${window.location.hash}');
    if (!window.location.hash.isEmpty) {
      var theme = window.location.hash.substring(1, window.location.hash.length).split('=')[1];
      term.setTheme(theme);
    } else if (window.localStorage.containsKey('theme')) {
      term.setTheme(window.localStorage['theme']);
    }
    
    // Setup the DnD listeners for file drop. 
    var body = document.body;
    body.on.dragEnter.add(_onDragEnter, false);
    body.on.dragOver.add(_onDragOver, false);
    body.on.drop.add(_onDrop, false);
  }
  
  void _onDragEnter(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();
    Element dropTarget = event.target;
    dropTarget.classes.add('dropping');
  }
  
  void _onDragOver(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();
    // Explicitly show this is a copy.
    event.dataTransfer.dropEffect = 'copy'; 
  }
  
  void _onDrop(MouseEvent event) {
    event.stopPropagation();
    event.preventDefault();
    Element dropTarget = event.target;
    dropTarget.classes.remove('dropping');
    term.addDroppedFiles(event.dataTransfer.files);
    term.writeOutput('<div>File(s) added!</div>');
  }
}

void main() {
  new TerminalFilesystem().run();
}
