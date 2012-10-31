// BUGS TO FILE:
// DOMFileSystem fs = filesystem; // XXX: dart:html should export this as FileSystem
// errorCallback: (e) {}); // XXX: getDirectory does not expose errorCallback, file bug. 
// print(filesystem.runtimeType); // XXX: does not work on compiling to javascript
// srcDirEntry.moveTo(destDirEntry); XXX: moveTo complains about incorrect parameters. 
class Terminal {

  DOMFileSystem fs;
  DirectoryEntry cwd;
  final cmdLineContainer;
  final outputContainer;
  final cmdLineInput; 
  OutputElement output;
  InputElement input;
  DivElement cmdLine;
  final VERSION = '0.0.1';
  Map CMDS;
  Terminal(this.cmdLineContainer,this.outputContainer, this.cmdLineInput) {
    cmdLine = document.query(cmdLineContainer);
    output = document.query(outputContainer);
    
    CMDS = {
                  'clear':clearCommand,
                  'help':helpCommand,
                  'version':versionCommand,       
                  'cat':catCommand,
                  'cd':cdCommand,
                  'date':dateCommand,
                  'ls':lsCommand,
                  'mkdir':mkdirCommand,
                  'mv':mvCommand,
                  'cp':mvCommand,
                  'open':openCommand,
                  'pwd':pwdCommand,
                  'rm':rmCommand,
                  'rmdir':rmdirCommand,
                  'theme':themeCommand,
                  'who':whoCommand
    };
    
    var history = [];
    var histpos = 0;
    
    window.on.click.add((var event) {
      cmdLine.focus();
    }, false);
    
    // Always force text cursor to end of input line.
    cmdLine.on.click.add((var event) {
      
    }, false);
    
    cmdLine.on.keyDown.add((KeyboardEvent event) {
      input = document.query(cmdLineInput);
      var histtemp = "";
      // historyHandler
      if (event.keyCode == 38 || event.keyCode == 40) {
        event.preventDefault();
        // up or down
        if (histpos < history.length) {
          history[histpos] = input.value;
        } else {
          histtemp = input.value;
        }
      }
      
      if (event.keyCode == 38) { // up
        histpos--;
        if (histpos < 0) {
          histpos = 0;
        }
      } else if (event.keyCode == 40) { // down
        histpos++;
        if (histpos >= history.length) {
          histpos = history.length - 1;
        }
      }
      
      if (event.keyCode == 38 || event.keyCode == 40) {
        // up or down
        input.value = history[histpos] ? history[histpos]  : histtemp; 
      }
    }, false);
    
    cmdLine.on.keyDown.add((KeyboardEvent event) { 
    
      // processNewCommand
      if (event.keyCode == 9) {
        event.preventDefault();
      } else if (event.keyCode == 13) { // enter
        
        input = document.query(cmdLineInput);
        
        if (input.value is String && !input.value.isEmpty) {
          history.add(input.value);
          histpos = history.length;
        }
        
        // move the line to output and remove id's
        DivElement line = input.parent.parent.clone(true);
        line.attributes.remove('id');
        line.classes.add('line');
        var c = line.query(cmdLineInput);
        c.attributes.remove('id');
        c.autofocus = false;
        c.readOnly = true;
        output.elements.add(line);
        String cmdline = input.value;
        input.value = ""; // clear input
        
        // Parse out command, args, and trim off whitespace
        var args;
        var cmd="";
        if (cmdline is String) {
          cmdline.trim();
          args = cmdline.split(' ');
          cmd = args[0].toLowerCase();
          args.removeRange(0, 1);
        }
        
        //switch(cmd) {
        //   default:
        //     output.insertAdjacentHTML('beforeEnd', '${cmd}: command not found');
        //};
        
        if (CMDS[cmd] is Function) {
          CMDS[cmd](cmd,args);
        } else {
          writeOutput('${cmd}: command not found');
        }
           
        window.scrollTo(0, window.innerHeight); 
        
      }
    }, false);
  }
  
  void initFS(bool persistent, int size) {
    writeOutput('<div>Welcome to ${document.title}'
                '! (v${VERSION})</div>');
    writeOutput(new Date.now().toLocal().toString());
    writeOutput('<p>Documentation: type "help"</p>');
    
    
    var type = persistent ? LocalWindow.PERSISTENT : LocalWindow.TEMPORARY;
    window.webkitRequestFileSystem(type, 
        size, 
        filesystemCallback, 
        errorHandler);
  }
  
  void filesystemCallback(filesystem) {
    fs = filesystem; // XXX: dart:html should export this as FileSystem
    cwd = fs.root;
    
//    print(filesystem.runtimeType);
//    print(cwd.runtimeType);

    // Attempt to create a folder to test if we can. 
    cwd.getDirectory('testquotaforfsfolder', 
        options: {'create': true},
        successCallback:  (DirectoryEntry dirEntry){
          dirEntry.remove(() { // If successfully created, just delete it.
            // noop.
          });
        });
        //errorCallback: (e) {}); // XXX: getDirectory does not expose errorCallback, file bug. 

//    errorCallback: (e) { // TODO: move to handler, looks messy...
//      if (e.code == FileError.QUOTA_EXCEEDED_ERR) {
//        writeOutput('ERROR: Write access to the FileSystem is unavailable. '
//               'Are you running Google Chrome with ' 
//               '--unlimited-quota-for-files?');
//      } else {
//        errorHandler(e);
//      }
//    });
  }
  
  void errorHandler(e) {
    var msg = '';
    switch (e.code) {
      case FileError.QUOTA_EXCEEDED_ERR:
        msg = 'QUOTA_EXCEEDED_ERR';
        break;
      case FileError.NOT_FOUND_ERR:
        msg = 'NOT_FOUND_ERR';
        break;
      case FileError.SECURITY_ERR:
        msg = 'SECURITY_ERR';
        break;
      case FileError.INVALID_MODIFICATION_ERR:
        msg = 'INVALID_MODIFICATION_ERR';
        break;
      case FileError.INVALID_STATE_ERR:
        msg = 'INVALID_STATE_ERR';
        break;
      case FileError.TYPE_MISMATCH_ERR:
        msg = 'TYPE_MISMATCH_ERR';
        break;
      default:
        msg = 'Unknown Error';
        break;
    };
    writeOutput('<div>Error: $msg </div>');
  }
  
  invalidOpForEntryType(FileError error, String cmd, String dest) {
    if (error.code == FileError.NOT_FOUND_ERR) {
      writeOutput('$cmd: $dest: No such file or directory<br>');
    } else if (error.code == FileError.INVALID_STATE_ERR) {
      writeOutput('$cmd: $dest: Not a directory<br>');
    } else if (error.code == FileError.INVALID_MODIFICATION_ERR) {
      writeOutput('$cmd: $dest: File already exists<br>');
    } else {
      errorHandler(error);
    }
  }
  
  void setTheme([String theme='default']) {
    var currentUrl = window.location.pathname;
    
    if (theme == 'default') {
      // history.replaceState({}, '', currentUrl);
      window.localStorage.remove('theme');
      document.body.classes.clear(); // XXX: is this same as, document.body.className = '';
      return;
    } else if (theme != null) {
      document.body.classes.add(theme);
      window.localStorage['theme'] = theme;
      //history.replaceState({}, '', currentUrl + '#theme=' + theme);
    }
  }
  
  void addDroppedFiles(List<File> files) {
    files.forEach((file) {
      cwd.getFile(file.name, 
          options: {'create': true, 'exclusive': true}, 
          successCallback: (FileEntry fileEntry) {
            fileEntry.createWriter((FileWriter fileWriter) {
              fileWriter.on.error.add((e)=>errorHandler(e));
              fileWriter.write(file);
            }, (e) => errorHandler(e));
          }, 
          errorCallback: (e) => errorHandler(e));
    });
  }
  
  read(var cmd, var fileName, var callback) {
    
  }
  
  clearCommand(var cmd, var args) {
    output.innerHTML = '';
    input.value = '';
  }
  
  helpCommand(var cmd, var args) {
    StringBuffer sb = new StringBuffer();
    sb.add('<div class="ls-files">');
    CMDS.keys.forEach((var k) {
      sb.add('${k}<br>');
    });
    sb.add('</div>');
    sb.add('<p>Add files by dragging them from your desktop.</p>');
    writeOutput(sb.toString());
  }
  
  versionCommand(String cmd, var args) {
    writeOutput("${VERSION}");
  }
  
  catCommand(String cmd, var args) {
    if (args.length >= 1) {
      var fileName = args[0];      
      if (fileName is String) {
        writeOutput('fileName=${fileName}');
        read(cmd, fileName, (var result) {
          writeOutput('<pre> ${result} </pre>');
        });
      } else {
        writeOutput('usage: ${cmd} filename');
      }
    } else {
      writeOutput('usage: ${cmd} filename');
    }
  }
  
  cdCommand(String cmd, List<String> args) {
    args = args == null ? [""] : args;
    StringBuffer sb = new StringBuffer();
    sb.addAll(args);
    var dest = sb.toString();
    if (dest.isEmpty) {
      dest = '/';
    }
    
    cwd.getDirectory(dest, 
        options: {}, 
        successCallback: (DirectoryEntry dirEntry){ 
          cwd = dirEntry;
          writeOutput('<div>${dirEntry.fullPath}</div>');
        },
        errorCallback: (FileError error) {
          invalidOpForEntryType(error, cmd, dest);
        });
  }
  
  dateCommand(String cmd, var args) {
    writeOutput(new Date.now().toLocal().toString());
  }
  
  StringBuffer formatColumns(List<Entry> entries) {
    var maxName = entries[0].name;
    for (int i = 0; i<entries.length; i++) {
      if (entries[i].name.length > maxName.length) {
        maxName = entries[i].name;
      }
    }
    
    // If we have 3 or less entires, shorten the output container's height.
    // 15 is the pixel height with a monospace font-size of 12px;
    var height = entries.length <= 3 ? 'height: ${(entries.length * 15)}px;' : '';
        
    // 12px monospace font yields ~7px screen width.
    var colWidth = maxName.length * 7;

    StringBuffer sb = new StringBuffer();
    sb.addAll(['<div class="ls-files" style="-webkit-column-width:',
     colWidth, 'px;', height, '">']);
    return sb;
  }
  
  Function readEntries;
  lsCommand(var cmd, var args) {
    Function success = (List<Entry> e) {
      if (e.length != 0) {
        
        StringBuffer html = formatColumns(e);
        for (int i = 0; i<e.length; i++) {
          html.addAll(['<span class="', e[i].isDirectory ? 'folder' : 'file','">', e[i].name, '</span><br>']);
        }
        html.add('</div>');
        writeOutput(html.toString());
      }
    };
    
    if (fs == null) {
      return;
    }
    
    // Read contents of current working directory. According to spec, need to
    // keep calling readEntries() until length of result array is 0. We're
    // guarenteed the same entry won't be returned again.
    var entries = [];
    DirectoryReader reader = cwd.createReader();
    readEntries = () {
      reader.readEntries(
          (List<Entry> results) {
            if (results.length == 0) {
              //entries.sort();
              success(entries);
            } else {
              entries.addAll(results);
              readEntries();
            }
          });
          //errorCallback: errorHandler);
    };
    
    readEntries();
  }
  
  createDir(rootDirEntry, List<String> folders, [opt_errorCallback = null]) {
    var errorCallback = opt_errorCallback;
    if (errorCallback == null) {
      errorCallback = errorHandler;
    }
    
    if (folders.length == 0) {
      return;
    }
    
    rootDirEntry.getDirectory(folders[0], 
        options: {'create': true}, 
        successCallback: (dirEntry) {
          // Recursively add the new subfolder if we still have a subfolder to create.
          if (folders.length != 0) {
//            if (folders.length == 1)  { 
//              
//            } else {
              folders.removeAt(0);
              createDir(dirEntry, folders);
//            }
          }
        }); // XXX: messed up callback signature 
        //errorCallback);
  }
  
  mkdirCommand(var cmd, List<String> args) {
    var dashP = false;
    var index = args.indexOf('-p');
    if (index != -1) {
      args.removeAt(index);
      dashP = true;
    }
    
    if (args.length == 0) {
      writeOutput('usage: $cmd [-p] directory<br>');
      return;
    }
    
    // Create each directory passed as an argument.
    for(int i=0; i<args.length; i++) {
      print('args = $args');
      var dirName = args[i];
      print('dirName = $dirName');
      if (dashP) {
        var folders = dirName.split('/');
        // Throw out './' or '/' if present on the beginning of our path.
        if (folders[0] == '.' || folders[0] == '') {
          //folders = folders.removeAt(0);
          folders.removeAt(0);
        }
        
        createDir(cwd, folders);
      } else {
        cwd.getDirectory(dirName, 
            options: {'create': true, 'exclusive': true}, 
            successCallback: (_){}); // XXX: still has that messed up signature. 
            //(e) { invalidOpForEntryType(e, cmd, dirName); });
      }
    }
  }
  
  mvCommand(String cmd, List<String> args) {
    if (args.length != 2) {
      writeOutput('usage: $cmd source target<br>'
                  '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$cmd'
                  ' source directory/');
      return;
    }
    
    var src = args[0];
    var dest = args[1];
    
    Function runAction = (c, srcDirEntry, destDirEntry, [opt_newName = null]) {
      var newName = "";
      if (opt_newName != null) newName = opt_newName;
      
      if (c == 'mv') {
        srcDirEntry.moveTo(destDirEntry); 
        // XXX: moveTo complains about incorrect parameters. 
//            name: destDirEntry.name,
//            // UNIX doesn't display output on successful move.
//            successCallback: (e) { return; },
//            errorCallback: (e) => errorHandler(e) 
//            );
      } else { // c=='cp'
        srcDirEntry.copyTo(destDirEntry);
        // XXX: copyTo complains about incorrect parameters. 
//        name: destDirEntry.name,
//            // UNIX doesn't display output on successful move.
//            successCallback: (e) {},
//            errorCallback: (e) => errorHandler(e) 
//            );
      }
    };
    
    // Moving to a folder? (e.g. second arg ends in '/').
    if (dest[dest.length - 1] == '/') {
      cwd.getDirectory(src, 
          options: {}, 
          successCallback: (srcDirEntry){
            // Create blacklist for dirs we can't re-create.
            var create = ['.', './', '..', '../', '/'].indexOf(dest) != -1 ? false : true;
            
            cwd.getDirectory(dest, 
                options: {'create': create}, 
                successCallback: (destDirEntry) => runAction(cmd, srcDirEntry, destDirEntry), 
                errorCallback: (error) => errorHandler(error));
          }, 
          errorCallback: (error) => errorHandler(error));
    } else { // Treat src/destination as files.
      cwd.getFile(src, options: {}, 
          successCallback: (srcFileEntry) {
            srcFileEntry.getParent((parentDirEntry) => runAction(cmd, srcFileEntry, parentDirEntry, dest),
                (error) => errorHandler(error));
          }, 
          errorCallback: (error) => errorHandler(error));
    }
  }
  
  openCommand(String cmd, List<String> args) {
    StringBuffer sb = new StringBuffer();
    sb.addAll(args);
    var fileName = sb.toString();
    
    if (fileName.isEmpty) {
      writeOutput('usage: $cmd filename');
      return;
    }
    
    open(cmd, fileName, (fileEntry) {
      var myWin = window.open(fileEntry.toURL(), 'mywin');
    });
  }
  
  open(String cmd, String path, successCallback) {
    if (fs == null) {
      return;
    }
    
    cwd.getFile(path, 
        options: {}, 
        successCallback: successCallback, 
        errorCallback: (e) {
          if (e.code == FileError.NOT_FOUND_ERR) {
            writeOutput('$cmd: $path: No such file or directory<br>');
          } else {
            errorHandler(e);
          }
        });
  }
  
  pwdCommand(String cmd, List<String> args) {
    writeOutput(cwd.fullPath);
  }
  
  rmCommand(var cmd, var args) {
    
  }
  
  rmdirCommand(var cmd, var args) {
    
  }
  
  themeCommand(var cmd, var args) {
    
  }
  
  whoCommand(var cmd, var args) {
    writeOutput('${document.title}'
    ' - By:  Eric Bidelman &lt;ericbidelman@chromium.org&gt;, Adam Singer &lt;financeCoding@gmail.com&gt;');
  }
  
  void writeOutput(String h) {
    output.insertAdjacentHTML('beforeEnd', h);
  }
}
