var gulp    = require("gulp");
var rename  = require("gulp-rename");
var install = require("gulp-install");
var zip     = require("gulp-zip");
var es      = require("event-stream");
var del     = require("del");
var path    = require("path");

var argv       = require("yargs").argv;
var production = !argv.debug;

gulp.task("build", ["env", "dependencies", "prepare"], function() {
  var outfile = argv.output || argv.o || (production ? "release.zip" : "debug.zip");
  var filename = path.basename(outfile);
  var dirpath = path.resolve(process.cwd(), path.dirname(outfile));
  var files = [
    "dist/**/*",
    "dist/*",
    "dist/.env.requirements",
    "dist/.env"
  ];

  return gulp.src(files)
    .pipe(zip(filename))
    .pipe(gulp.dest(dirpath));
});

gulp.task("clean", function() {
  return del([ "dist", "release.zip", "debug.zip" ])
});

gulp.task("prepare", function() {
  return gulp.src([ "src/*", ".env.requirements" ])
    .pipe(gulp.dest("dist"))
});

gulp.task("dependencies", function() {
  return gulp.src("package.json")
    .pipe(gulp.dest("dist"))
    .pipe(install({ production: production }))
});

gulp.task("env", function() {
  return gulp.src(".env.requirements")
    .pipe(writeEnv({ env: upcaseObject(argv) }))
    .pipe(rename(".env"))
    .pipe(gulp.dest("dist"));
});

function upcaseObject(src) {
  var dest = {};

  Object.keys(src).forEach(function(key) {
    dest[key.toUpperCase()] = src[key];
  });

  return dest;
}

function writeEnv(options) {
  var env = (options || process).env;

  return es.map(function(file, cb) {
    var content = file.contents.toString().replace(/^#.*\n/, "");
    var lines = content.split(/\n+/).filter(function(a) { return a });
    var buffer = [];

    for (var i = 0; i < lines.length; i++) {
      var parts = lines[i].split("=", 1);
      var key = parts[0];
      var defaultValue = parts[1];
      var value = env[key] || defaultValue || null;

      buffer.push([key, value].join("="));
    }

    file.contents = new Buffer(buffer.join("\n"));
    cb(null, file);
  });
}
