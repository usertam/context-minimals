#!/usr/bin/env python3
# coding: utf-8
#
# Copyright 2021-2022 (C) Pablo Rodríguez
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA or see <http://www.gnu.org/licenses/gpl.html>.

import os, sys, shutil
import xml.etree.ElementTree as ET
import cairo
import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gst", "1.0")
from gi.repository import Gtk, Gdk, GObject, GLib, Gst, GdkPixbuf
gi.require_version('Poppler', '0.18')
from gi.repository import Poppler

Gst.init(sys.argv)

class gvoz:
    def __init__(self):

        self.execname = os.path.splitext(os.path.basename(sys.argv[0]))[0]
        self.real_path = os.path.dirname(os.path.realpath(os.path.abspath(sys.argv[0])))
        self.program_version = "0.9.9.2"

        if(len(sys.argv) < 2):
            self.on_file_selection()
            print("")
            print("  " + self.execname + "-" + self.program_version
                + " (https://gvoz.presvoz.tk)")
            print("  Written by Pablo Rodríguez")
            print("  Usage: " + self.execname + " presentation.pdf")
            print("")

        if len(sys.argv) > 1:
            self.main_filename = sys.argv[1]
        elif self.dialog_filename != "":
            self.main_filename = self.dialog_filename

        self.filename = os.path.splitext(self.main_filename)[0]

        if os.path.splitext(self.main_filename)[1] != (".pdf" or ".PDF"):
            self.pdffilename = os.path.splitext(self.main_filename)[0] + ".pdf"
            if  os.path.isfile(self.pdffilename) == False:
                self.pdffilename = os.path.splitext(self.main_filename)[0] + ".PDF"
                if os.path.isfile(self.pdffilename) == False:
                    self.on_file_selection()
            elif os.path.isfile(self.pdffilename) == False:
                self.on_file_selection()
        else:
            self.pdffilename = self.main_filename

        self.define_soundtimesnames()

        self.uri = Gst.filename_to_uri(os.path.abspath(self.pdffilename))

        self.document = Poppler.Document.new_from_file(self.uri, None)
        self.n_pages = self.document.get_n_pages()
        self.page_selector = self.document.get_page(0)
        self.current_page = 0

        self.win = Gtk.Window()
        self.win.set_icon_from_file(self.real_path + '/gvoz.svg')
        self.doc_title = self.document.get_title() or "χαλεπὰ τὰ καλά"
        self.win.set_title (self.execname + " — " + str(self.current_page + 1) + "/" + str(self.n_pages) + " — " + self.doc_title)

        self.win.set_default_size(500, 500)
        self.win.set_position(Gtk.WindowPosition.CENTER_ALWAYS)

        self.box = Gtk.Box()

        self.area = Gtk.DrawingArea()
        self.area.connect("draw", self.on_draw)

        self.box.pack_start(self.area, True, True, 0)

        self.win.add(self.box)
        self.win.connect("destroy", Gtk.main_quit)
        self.win.show_all()

        self.win.connect('key-press-event', self.key_press_event)

        self.width, self.height = self.win.get_size()
        self.page_width, self.page_height= self.page_selector.get_size()

        self.surface = cairo.ImageSurface(cairo.FORMAT_RGB24,
                                          int(self.width),
                                          int(self.height))

        if sys.platform.startswith('win'):
            self.player = Gst.parse_launch("wasapisrc low-latency=true ! audio/x-raw,format=F32LE ! wavenc ! filesink location=\"" + self.audiofilename + "\"")
        else:
            self.player = Gst.parse_launch("autoaudiosrc ! audio/x-raw,format=F32LE,rate=48000,channels=1 ! wavenc ! filesink location=\"" + self.audiofilename + "\"")

        bus = self.player.get_bus()
        bus.add_signal_watch()
        bus.connect('message', self.on_message)

        xmp = self.document.get_metadata()
        if xmp != None and xmp != "":
            xmp_root = ET.fromstring(xmp)
            for language in xmp_root.findall(".//{http://purl.org/dc/elements/1.1/}language"):
                doc_lang = language.text
        else:
            print("The PDF document has no language information")

        title_separator = ". "

        self.sound_metadata = { "title" : "The Title" }
        self.sound_metadata["genre"] = "Other/Presentation"
        self.sound_metadata["application-name"] = "GVoz"
        self.sound_metadata["encoder"] = self.sound_metadata["application-name"]
        self.sound_metadata["encoder-version"] = self.program_version
        self.sound_metadata["datetime"] = Gst.DateTime.new_now_local_time()
        self.sound_metadata["date"] = GLib.Date.new_dmy(self.sound_metadata["datetime"].get_day(),
            self.sound_metadata["datetime"].get_month(), self.sound_metadata["datetime"].get_year())

        try:
            doc_lang
        except NameError:
            print("\n\"" + os.path.basename(self.pdffilename) +
                "\" contains no language information.")
            self.doc_lang = None
        else:
            if doc_lang != None and doc_lang != "":
                self.sound_metadata["language-code"] = doc_lang
                self.sound_metadata["language-name"] = GstTag.tag_get_language_name(language_code)
            if doc_lang.startswith('en'):
                title_separator = ": "
            else:
                title_separator = ". "

        if self.document.get_subject() != None and self.document.get_subject() != "":
            self.sound_metadata["comment"] =  self.document.get_subject()
        elif self.document.get_title() != None and self.document.get_title() != "":
            self.sound_metadata["title"] = self.document.get_title()
        if self.document.get_keywords() != None and self.document.get_keywords() != "":
            self.sound_metadata["keywords"] = self.document.get_keywords()
        if self.document.get_author() != None and self.document.get_author() != "":
            self.sound_metadata["artist"] = self.document.get_author()
            self.sound_metadata["copyright"] = "© " + str(self.sound_metadata["datetime"].get_year()) + " " + self.document.get_author()
        else:
            self.sound_metadata["copyright"] = "© " + str(self.sound_metadata["datetime"].get_year())

        self.taglist = Gst.TagList.new_empty()

        self.mp3_converter = Gst.parse_launch("filesrc location=\"" + self.audiofilename + "\" ! decodebin ! audioconvert ! audioresample ! lamemp3enc mono=true cbr=true target=bitrate bitrate=32 ! id3v2mux ! filesink location=\"" + self.mp3_audio + "\"")

        mp3_bus = self.mp3_converter.get_bus()
        mp3_bus.add_signal_watch()
        mp3_bus.connect('message', self.on_mp3_message)

        self.mp3_metadata = True

        tagsetter = self.mp3_converter.get_by_interface(Gst.TagSetter)
        for tag_key, tag_value in self.sound_metadata.items():
            try:
                self.taglist.add_value(Gst.TagMergeMode.REPLACE, tag_key, tag_value)
            except ValueError:
                print("WARNING: skipping tag %s; value %s is not valid" % (tag_key, tag_value))
        if not self.taglist.is_empty() and self.mp3_metadata:
            tagsetter.merge_tags(self.taglist, Gst.TagMergeMode.REPLACE_ALL)
            print(type(self.mp3_metadata))
            print(self.taglist.to_string() + "\n")
        else:
            print("<<<< WARNING: Could not find element to set tags. >>>")

        # ~ self.opus_converter = Gst.parse_launch("filesrc location=\"" + self.audiofilename + "\" ! decodebin ! audioconvert ! audioresample ! opusenc audio-type=voice bitrate=16000 ! oggmux ! filesink location=\"" + self.opus_audio + "\"")

        # ~ opus_bus = self.opus_converter.get_bus()
        # ~ opus_bus.add_signal_watch()
        # ~ opus_bus.connect('message', self.on_opus_message)

        # ~ self.opus_metadata = True

        # ~ tagsetter = self.opus_converter.get_by_interface(Gst.TagSetter)
        # ~ if not self.taglist.is_empty() and self.opus_metadata:
            # ~ tagsetter.merge_tags(self.taglist, Gst.TagMergeMode.REPLACE_ALL)
        # ~ else:
            # ~ print("<<<< WARNING: Could not find element to set tags. >>>")

        self.use_presvoz = True

    def on_message(self, bus, message):
        t = message.type
        if t == Gst.MessageType.EOS:
            self.player.set_state(Gst.State.NULL)
            # ~ Gtk.main_quit()
        elif t == Gst.MessageType.ERROR:
            err, debug = message.parse_error()
            print ("Error: %s" % err, debug)
            self.player.set_state(Gst.State.NULL)

    def on_mp3_message(self, mp3_bus, message):
        t = message.type
        if t == Gst.MessageType.EOS:
            self.mp3_converter.set_state(Gst.State.NULL)
            self.generate_presentation()
            Gtk.main_quit()
        elif t == Gst.MessageType.ERROR:
            err, debug = message.parse_error()
            print ("Error: %s" % err, debug)
            self.mp3_converter.set_state(Gst.State.NULL)

    # ~ def on_opus_message(self, opus_bus, message):
        # ~ t = message.type
        # ~ if t == Gst.MessageType.EOS:
            # ~ self.opus_converter.set_state(Gst.State.NULL)
            # ~ Gtk.main_quit()
        # ~ elif t == Gst.MessageType.ERROR:
            # ~ err, debug = message.parse_error()
            # ~ print ("Error: %s" % err, debug)
            # ~ self.opus_converter.set_state(Gst.State.NULL)

    def generate_presentation (self):
        if shutil.which("context") != None and shutil.which("context") != "" and self.use_presvoz:
            os.system("context --purgeall --extra=third-presvoz " + self.pdffilename)
            if os.path.isfile(self.js_timesfilename):
                os.remove(self.js_timesfilename)

    def define_soundtimesnames (self):
        if sys.platform.startswith('win'):
            self.audiofilename = self.filename.replace("\\", "/") + "-audio.wav"
            self.mp3_audio = self.filename.replace("\\", "/") + "-audio.mp3"
            self.opus_audio = self.filename.replace("\\", "/") + "-audio.opus"
        else:
            self.audiofilename = self.filename + "-audio.wav"
            self.mp3_audio = self.filename + "-audio.mp3"
            self.opus_audio = self.filename + "-audio.opus"

        self.times = []
        self.timesfilename =  self.filename + '-times.txt'
        self.js_timesfilename =  self.filename + '-times.js'

    def on_metadata_info (self):
        if self.document.get_title() != None and self.document.get_title() != "":
            metadata_info = "\n<b>Title:</b> <i>" + self.document.get_title() + "</i>"
            if self.document.get_author() != None and self.document.get_author() != "":
                metadata_info += "\n\n<b>Author:</b> <i>" + self.document.get_author() + "</i>"
            if self.document.get_subject() != None and self.document.get_subject() != "":
                metadata_info += "\n\n<b>Comments:</b> <i>" + self.document.get_subject() + "</i>"
            if self.document.get_keywords() != None and self.document.get_keywords() != "":
                metadata_info += "\n\n<b>Keywords:</b> <i>" + self.document.get_keywords() + "</i>"
            if self.doc_lang != None and self.doc_lang != "":
                metadata_info += "\n\n<b>Language:</b> <i>" + self.sound_metadata['language-name'] + "</i>"
        else:
            metadata_info = "\nThe PDF document contains no metadata"


            self.sound_metadata["comment"] =  self.document.get_subject()
        if self.document.get_author() != None and self.document.get_author() != "":
            self.sound_metadata["artist"] = self.document.get_author()
            self.sound_metadata["copyright"] = "© " + str(self.sound_metadata["datetime"].get_year()) + " " + self.document.get_author()
        else:
            self.sound_metadata["copyright"] = "© " + str(self.sound_metadata["datetime"].get_year())

        dialog = Gtk.MessageDialog(
            # ~ transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="Metadata from PDF Document",
        )

        dialog.format_secondary_text(metadata_info)

        dialog.props.secondary_use_markup = True

        dialog.run()

        dialog.destroy()

    def on_keys_info (self):
        keys_info = "\n<b>space</b>\t\tGo to next slide and write its time"
        keys_info += "\n\t\t\tThis starts and finishes sound recording"
        keys_info += "\n\t\t\tAfter that, <i>PresVoz</i> will generate the presentation"
        keys_info += "\n\n<b>a</b>\t\t\tAbout <i>GVoz</i>"
        keys_info += "\n\n<b>c</b>\t\t\tDon’t generate PDF and <i>Flash</i> presentations with <i>PresVoz</i>"
        keys_info += "\n\n<b>d</b>\t\t\tShow metadata imported from the PDF document"
        keys_info += "\n\n<b>h</b>\t\t\tShow key information"
        keys_info += "\n\n<b>m</b>\t\t\tEnable mouse–click to advance slides"
        keys_info += "\n\n<b>p</b>\t\t\tPause / unpause sound and times recording"
        keys_info += "\n\t\t\tWith paused recording, <i>GVoz</i> will exit full–screen"
        keys_info += "\n\t\t\tWith recording started again, <i>GVoz</i> will go full–screen"
        # ~ keys_info += "\n\n<b>x</b>\t\t\tRemove metadata in MP3 file\n\t\t\tTitle and author are read from the PDF document\n\t\t\tDates and times are set from the recording"
        keys_info += "\n\n<b>q</b>\t\t\tQuit <i>GVoz</i> (presentation won’t be generated)"

        dialog = Gtk.MessageDialog(
            # ~ transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="Keyboard Info",
        )
        dialog.format_secondary_text(
            keys_info
        )

        dialog.props.secondary_use_markup = True

        dialog.run()

        dialog.destroy()

    def on_presvoz_info (self):
        presvoz_info = "\nPresentation won’t be generated after sound and times recording."
        presvoz_info += "\n\nIf you want to generate it, just use <i>Presvoz</i> after <i>GVoz</i> finishes."

        dialog = Gtk.MessageDialog(
            # ~ transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="Presentation Disabled",
        )
        dialog.format_secondary_text(
            presvoz_info
        )

        dialog.props.secondary_use_markup = True

        dialog.run()

        dialog.destroy()

    def on_mouse_info (self):
        mouse_info = "\nMouse has been activated to advance slides."
        mouse_info += "\n\nMouse–clicks have been enabled to advance slides."
        mouse_info += "\n\nThere is no way to disable the mouse again."

        dialog = Gtk.MessageDialog(
            # ~ transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="Mouse Enabled",
        )
        dialog.format_secondary_text(mouse_info)

        dialog.props.secondary_use_markup = True

        dialog.run()

        dialog.destroy()

    def on_presvoz_presentation (self):
        presvoz_presentation = "\nThe selected PDF document is already a presentation with voice."
        presvoz_presentation += "\n\nPlease, select other PDF document not already generated by <i>PresVoz</i>."

        dialog = Gtk.MessageDialog(
            # ~ transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text="<big><b><i>PresVoz</i> Presentation Detected</b></big>",
        )

        dialog.format_secondary_text(presvoz_presentation)

        dialog.props.use_markup = True
        dialog.props.secondary_use_markup = True

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            self.on_file_selection()

        dialog.run()

        dialog.destroy()

    def on_existing_files (self):
        already_recorded_files = "\nVoice and times have already been recorded in a previous session."
        already_recorded_files += "\n\nIf you proceed, <tt>" + os.path.basename(self.audiofilename) + "</tt> and <tt>" + os.path.basename(self.timesfilename) + "</tt> will be lost forever."
        already_recorded_files += "\n\nIf you cancel, you will quit <i>GVoz</i>."
        already_recorded_files += "\n\nIf you want to keep <tt>" + os.path.basename(self.audiofilename) + "</tt> and <tt>" + os.path.basename(self.timesfilename) + "</tt>, please quit and rename them or move them to another directory."
        already_recorded_files += "\n\nDo you really want to proceed?\n"

        dialog = Gtk.MessageDialog(
            # ~ transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.WARNING,
            buttons=Gtk.ButtonsType.YES_NO,
            text="Existing Sound and Times",
        )

        dialog.format_secondary_text(already_recorded_files)

        dialog.set_default_response(Gtk.ResponseType.NO)

        dialog.props.secondary_use_markup = True

        response = dialog.run()
        if response == Gtk.ResponseType.YES:
            if os.path.isfile(self.audiofilename):
                os.remove(self.audiofilename)
            if os.path.isfile(self.timesfilename):
                os.remove(self.timesfilename)
            if os.path.isfile(self.mp3_audio):
                os.remove(self.mp3_audio)
            if os.path.isfile(self.opus_audio):
                os.remove(self.opus_audio)
        elif response == Gtk.ResponseType.NO:
            Gtk.main_quit()

        dialog.destroy()

    def button_press_event(self, widget, event):
        if event.button == 1:
            self.record_and_advance()

    def key_press_event(self, widget, event):
      if event.keyval != Gdk.keyval_from_name("a"):
        if  event.keyval != Gdk.keyval_from_name("h"):
          if  event.keyval != Gdk.keyval_from_name("q"):
            if  event.keyval != Gdk.keyval_from_name("x"):
              if  event.keyval != Gdk.keyval_from_name("c"):
                if  event.keyval != Gdk.keyval_from_name("m"):
                  if event.keyval != Gdk.keyval_from_name("d"):
                    if self.player.get_state(0)[1] == Gst.State.NULL and self.current_page + 1 <= self.n_pages:
                      if os.path.exists(self.audiofilename) or os.path.exists(self.timesfilename):
                        self.on_existing_files()
                      elif self.document.get_subject() != None:
                        if self.document.get_subject().endswith('🤞🐞 – https://www.presvoz.tk'):
                          self.on_presvoz_presentation()
        if event.keyval == Gdk.keyval_from_name("h"):
            self.on_keys_info()
        if event.keyval == Gdk.keyval_from_name("a"):
            self.about_info()
        if event.keyval == Gdk.keyval_from_name("q"):
            if self.player.get_state(0)[1] == Gst.State.PLAYING or self.player.get_state(0)[1] == Gst.State.PAUSED:
                self.player.set_state(Gst.State.NULL)
                self.file_times.close()
            if os.path.isfile(self.audiofilename):
                self.mp3_converter.set_state(Gst.State.PLAYING)
                self.win.set_title (self.execname + " — Converting sound to MP3 format…")
            Gtk.main_quit()
        if event.keyval == Gdk.keyval_from_name("x"):
            self.mp3_metadata = False
            self.opus_metadata = False
        if event.keyval == Gdk.keyval_from_name("c"):
            self.use_presvoz = False
            self.on_presvoz_info()
        if event.keyval == Gdk.keyval_from_name("d"):
            self.on_metadata_info()
        if event.keyval == Gdk.keyval_from_name("m"):
            self.win.connect('button-press-event', self.button_press_event)
            self.on_mouse_info()
        if event.keyval == Gdk.keyval_from_name("p"):
            if self.player.get_state(0)[1] == Gst.State.PLAYING:
                self.win.unfullscreen()
                self.win.set_title (self.execname + " — " + str(self.current_page + 1) + "/" + str(self.n_pages) + " — " + self.doc_title)
                self.player.set_state(Gst.State.PAUSED)
            elif self.player.get_state(0)[1] == Gst.State.PAUSED:
                self.win.fullscreen()
                self.player.set_state(Gst.State.PLAYING)
        if event.keyval == Gdk.keyval_from_name("space"):
            self.record_and_advance()

    def record_and_advance(self):
        if self.player.get_state(0)[1] == Gst.State.NULL and self.current_page + 1 <= self.n_pages:
            self.win.fullscreen()
            self.player.set_state(Gst.State.PLAYING)
            self.file_times = open(self.timesfilename, 'w')
        elif self.player.get_state(0)[1] == Gst.State.PLAYING:
            if self.current_page + 1 < self.n_pages:
                self.current_page += 1
                self.page_selector = self.document.get_page(self.current_page)
                self.area.set_size_request(int(self.width),int(self.height))
                self.area.queue_draw()
                self.file_times.write(str(int(self.player.get_pipeline_clock().get_time()/1000000)) + "\n")
            elif self.current_page + 1 == self.n_pages:
                self.win.unfullscreen()
                self.win.set_title (self.execname + " — " + str(self.current_page + 1) + "/" + str(self.n_pages) + " — " + self.doc_title)
                self.player.send_event(Gst.Event.new_eos())
                self.file_times.write(str(int(self.player.get_pipeline_clock().get_time()/1000000)))
                self.file_times.close()
                self.current_page += 1
                self.mp3_converter.set_state(Gst.State.PLAYING)
                self.win.set_title (self.execname + " — Converting sound to MP3 format…")
                if shutil.which("context") != None and shutil.which("context") != "" and self.use_presvoz:
                    self.win.set_title (self.execname + " — Generating presentation…")
                # ~ self.opus_converter.set_state(Gst.State.PLAYING)
                # ~ self.win.set_title (self.execname + " — Converting sound to Opus format…")

    def on_file_selection(self):
        dialog = Gtk.FileChooserDialog(
            title="Please choose a PDF document", action=Gtk.FileChooserAction.OPEN
        )
        dialog.add_buttons(
            Gtk.STOCK_CANCEL,
            Gtk.ResponseType.CANCEL,
            Gtk.STOCK_OPEN,
            Gtk.ResponseType.OK,
        )

        self.add_filters(dialog)

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            self.dialog_filename = dialog.get_filename()
            self.pdffilename = self.dialog_filename
            self.filename = os.path.splitext(self.dialog_filename)[0]
            self.define_soundtimesnames()

        dialog.destroy()

    def add_filters(self, dialog):
        filter_pdf = Gtk.FileFilter()
        filter_pdf.set_name("PDF documents")
        filter_pdf.add_mime_type("application/pdf")
        dialog.add_filter(filter_pdf)

    def on_draw(self, widget, cairo_context):
        add_x = 0
        add_y = 0

        if (self.area.get_allocated_width()/self.page_width) < (self.area.get_allocated_height()/self.page_height):
            self.scale = self.area.get_allocated_width()/self.page_width
            add_y = (((self.area.get_allocated_height()-(self.page_height*self.scale))/2)/self.scale)
        else:
            self.scale = self.area.get_allocated_height()/self.page_height
            add_x = (((self.area.get_allocated_width()-(self.page_width*self.scale))/2)/self.scale)

        # ~ cr = Gdk.cairo_create(self.win.get_window()) # deprecated
        # ~ cairo_context = cairo.Context(self.surface) # new, seems not required

        cairo_context.set_source_surface(self.surface)
        cairo_context.set_source_rgba(1, 1, 1)

        if self.scale != 1:
            cairo_context.scale(self.scale, self.scale)

        cairo_context.translate(add_x, add_y)
        cairo_context.rectangle(0, 0, self.page_width, self.page_height)
        cairo_context.fill()
        self.page_selector.render(cairo_context)

    def about_info (self):
        dialog = Gtk.AboutDialog()
        dialog.set_program_name("GVoz")
        dialog.set_version(self.program_version)
        dialog.set_comments("Record and create presentations with voice")
        dialog.set_website("https://gvoz.presvoz.tk")
        dialog.set_website_label("https://gvoz.presvoz.tk")
        dialog.set_authors(["Pablo Rodríguez"])
        dialog.set_copyright("© 2021-2022 Pablo Rodríguez")
        dialog.set_license_type(Gtk.License.GPL_2_0)
        dialog.set_wrap_license = True
        dialog.set_logo(GdkPixbuf.Pixbuf.new_from_file(self.real_path + "/gvoz.svg"))
        dialog.connect('response', lambda dialog, data: dialog.destroy())
        dialog.show_all()

    def gtk_main_quit(self, widget, event):
        Gtk.main_quit()

    def main(self):
        Gtk.main()

gv = gvoz()
gv.main()
