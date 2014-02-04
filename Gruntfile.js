'use strict';

module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('Selectr.jquery.json'),
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',
    // Task configuration.
    clean: {
      files: ['dist']
    },
    concat: {
      options: {
        banner: '<%= banner %>',
        stripBanners: true
      },
      dist: {
        src: ['src/<%= pkg.name %>.js'],
        dest: 'dist/<%= pkg.name %>.js'
      }
    },
    uglify: {
      options: {
        banner: '<%= banner %>'
      },
      dist: {
        src: '<%= concat.dist.dest %>',
        dest: 'dist/<%= pkg.name %>.min.js'
      }
    },
    karma: {
      unit: {
        configFile: 'conf/karma.conf.js',
        runnerPort: 9999,
        singleRun: true,
        browsers: ['PhantomJS']
      }
    },
    jshint: {
      src: {
        options: {
          jshintrc: 'conf/.jshintrc'
        },
        src: ['src/**/*.js']
      }
    },
    watch: {
//      src: {
//        files: '<%= jshint.src.src %>',
//        tasks: ['jshint:src']
//      },
      coffeeSrc: {
        files: ['src/**/*.coffee'],
        tasks: ['coffee:devSrc', 'docco:generate']
      },
      coffeetest: {
        files: ['test/**/*.coffee'],
        tasks: ['coffee:devTest']
      },
//      test: {
//        files: ['test/**/*.js'],
//        tasks: ['karma']
//      },
      compass: {
        files: ['src/*.scss'],
        tasks: ['compass:dev']
      }
    },
    coffee: {
      devSrc: {
        options: {
//          bare: true,
          sourceMap: true
        },
        files: {
          'src/Selectr.js': 'src/Selectr.coffee'
        }
      },
      devTest: {
        options: {
          bare: true
        },
        files: {
          'test/SelectrTests.js': 'test/SelectrTests.coffee'
        }
      },
      dist: {
        options: {
          bare: true
        },
        files: {
          'dist/Selectr.js': 'src/Selectr.coffee'
        }
      }
    },
    compass: {                  // Task
      dist: {                   // Target
        options: {              // Target options
          sassDir: 'src',
          cssDir: 'dist',
          imagesDir: 'src/images',
          imagesPath: 'src/images',
          environment: 'production',
          relativeAssets: true
        }
      },
      dev: {
        options: {
          sassDir: 'src',
          cssDir: 'src',
          imagesDir: 'src/images',
          imagesPath: 'src/images',
          relativeAssets: true
        }
      }
    },
    docco: {
      generate: {
        src: ["src/Selectr.coffee"],
        options: {
          layout: "linear" // parallel, classic, linear
        }
      },
      debug: {
        src: ["test/**/*.coffee"],
        options: {
          output: "docs/test",
          layout: "linear"
        }
      }
    },
    coffeelint: {
      app: ['src/*.coffee'],
      tests: {
        files: {
          src: ['test/*.coffee']
        },
        options: {
          'no_trailing_whitespace': {
            'level': 'error'
          }
        }
      }
    },
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-watch');
//  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-compass');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-karma');
  grunt.loadNpmTasks('grunt-docco');
  grunt.loadNpmTasks('grunt-coffeelint');



  // Default task.
  grunt.registerTask('test', ['coffeelint:app', 'karma']);
  grunt.registerTask('default', ['compass:dev', 'coffee:dev', 'karma', 'clean', 'concat', 'uglify']);
  grunt.registerTask('dist', ['compass:dist', 'coffee:dist', 'karma', 'clean', 'concat', 'uglify']);

};
