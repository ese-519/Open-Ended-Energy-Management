import sys
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEvent, FileSystemEventHandler

class MyHandler(FileSystemEventHandler):
  def __init__(self, target_file_path):
    self.target_file_path = target_file_path
    self.flag_done = False

  def process_done(self):
    return self.flag_done

  def process(self, event):
    self.flag_done = True
    print event.src_path, event.event_type

  def on_created(self, event):
    if event.src_path == self.target_file_path:
      self.process(event)

  def on_modified(self, event):
    if event.src_path == self.target_file_path:
      self.process(event)


if __name__ == "__main__":
    observer_path = sys.argv[1] if len(sys.argv) > 1 else '.'
    target_path = sys.argv[2] if len(sys.argv) == 2 else './foo.txt'
    observer = Observer()
    observer.schedule(MyHandler(target_path), observer_path, recursive=True)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
