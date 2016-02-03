/**
	DXV
	Version 0.4
	This command-line utility validates an XML file or recursively searches a path and validates each XML file inside it.
	It requires Simple Logger from https://github.com/Oire/dutils

	Copyright 2016, Andre Polykanine A.K.A. Menelion Elensúlë
	https://github.com/Oire
*/

module oire.dutils.dxv;

import std.stdio;
import std.file;
import std.string: format;
static import std.xml;
import std.parallelism: parallel;
import std.getopt;
import std.experimental.logger;
import std.conv: to;

final void validate(in string f) {
	string s = to!string(std.file.read(f));
	std.xml.check(s);
}

void main(string[] args) {
	bool quiet;
	string logFile;
	auto cliOptions = getopt(args,
			std.getopt.config.caseSensitive,
			std.getopt.config.passThrough,
			"quiet|q", "If set, success messages are not output", &quiet,
			"log", "If set, the results will be output to a given file", &logFile
	);
	if (cliOptions.helpWanted || args.length<2) {
		defaultGetoptPrinter(format("Usage: %s [options] <filename>|<foldername> [<filename>|<foldername> ...]\nAvailable options:", args[0]), cliOptions.options);
	} else {
		auto logging = (logFile !is null && logFile != "")? new FileLogger(logFile): new FileLogger(stdout);
		foreach(f; parallel(args[1..$])) {
			if (isDir(f)) {
				auto dirIter = dirEntries(f, "*.xml", SpanMode.depth);
				foreach(dirFile; parallel(dirIter, 1)) {
					try {
						validate(dirFile);
						if (!quiet) {
							logging.infof("%s: Validation passed", dirFile);
						}
					} catch(Exception e) {
						logging.errorf("Failed to validate %s: %s", dirFile, to!string(e));
					}
				}
			} else { // A single file
				try {
					validate(f);
					if (!quiet) {
						logging.infof("%s: Validation passed", f);
					}
				} catch(Exception e) {
					logging.errorf("Error validating %s: %s", f, to!string(e));
				}
			}
		}
	}
}