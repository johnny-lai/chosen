module.exports = (grunt) ->
  version = ->
    grunt.file.readJSON("package.json").version
  version_tag = ->
    "v#{version()}"

  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    comments: """
/*!
Chosen, a Select Box Enhancer for jQuery and Prototype
by Patrick Filler for Harvest, http://getharvest.com

Version <%= pkg.version %>
Full source at https://github.com/harvesthq/chosen
Copyright (c) 2011 Harvest http://getharvest.com

MIT License, https://github.com/harvesthq/chosen/blob/master/LICENSE.md
This file is generated by `grunt build`, do not edit it by hand.
*/
\n
"""
    minified_comments: "/* Chosen #{version_tag()} | (c) 2011-2013 by Harvest | MIT License, https://github.com/harvesthq/chosen/blob/master/LICENSE.md */\n"

    concat:
      options:
        banner: "<%= comments %>"
      jquery:
        src: ["public/chosen.jquery.js"]
        dest: "public/chosen.jquery.js"
      proto:
        src: ["public/chosen.proto.js"]
        dest: "public/chosen.proto.js"
      css:
        src: ["public/chosen.css"]
        dest: "public/chosen.css"

    coffee:
      options:
        join: true
      compile:
        files:
          'public/chosen.jquery.js': [
            'coffee/lib/select-parser.coffee',
            'coffee/lib/data-source.coffee',
            'coffee/lib/array-data-source.coffee',
            'coffee/lib/callback-data-source.coffee',
            'coffee/lib/url-data-source.jquery.coffee',
            'coffee/lib/abstract-chosen.coffee',
            'coffee/chosen.jquery.coffee'
          ]
          'public/chosen.proto.js': [
            'coffee/lib/select-parser.coffee',
            'coffee/lib/data-source.coffee',
            'coffee/lib/array-data-source.coffee',
            'coffee/lib/callback-data-source.coffee',
            'coffee/lib/abstract-chosen.coffee',
            'coffee/chosen.proto.coffee'
          ]

    uglify:
      options:
        mangle:
          except: ['jQuery', 'AbstractChosen', 'Chosen', 'SelectParser',
                   'DataSource', 'CallbackDataSource', 'ArrayDataSource', 'URLDataSource']
        banner: "<%= minified_comments %>"
      minified_chosen_js:
        files:
          'public/chosen.jquery.min.js': ['public/chosen.jquery.js']
          'public/chosen.proto.min.js': ['public/chosen.proto.js']

    compass:
      chosen_css:
        options:
          specify: ['sass/chosen.scss', 'sass/chosen-ie7.scss']

    cssmin:
      minified_chosen_css:
        options:
          banner: "<%= minified_comments %>"
          keepSpecialComments: 0
        src: 'public/chosen.css'
        dest: 'public/chosen.min.css'

    watch:
      scripts:
        files: ['coffee/**/*.coffee', 'sass/*.scss']
        tasks: ['build']

    copy:
      dist:
        files: [
          { cwd: "public", src: ["index.html", "index.proto.html", "chosen.jquery.js", "chosen.jquery.min.js", "chosen.proto.js", "chosen.proto.min.js", "chosen.css", "chosen-sprite.png", "chosen-sprite@2x.png"], dest: "dist/", expand: true, flatten: true, filter: 'isFile' }
          { src: ["public/docsupport/**"], dest: "dist/docsupport/", expand: true, flatten: true, filter: 'isFile' }
        ]

    clean:
      dist: ["dist/"]
      chosen_zip: ["*.zip"]

    build_gh_pages:
      gh_pages: {}

    dom_munger:
      latest_version:
        src: ['public/index.html', 'public/index.proto.html', 'public/options.html']
        options:
          callback: ($) ->
            $("#latest-version").text(version_tag())
    zip:
      chosen:
        cwd: 'public/'
        src: ['public/**/*']
        dest: "chosen_#{version_tag()}.zip"
        
    connect:
      server:
        options:
          hostname: '*'
          base: './public'
    
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-compass'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-build-gh-pages'
  grunt.loadNpmTasks 'grunt-zip'
  grunt.loadNpmTasks 'grunt-dom-munger'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  
  grunt.registerTask 'default', ['build']
  grunt.registerTask 'build', ['coffee', 'compass', 'concat', 'uglify', 'cssmin']
  grunt.registerTask 'gh_pages', ['copy:dist', 'build_gh_pages:gh_pages']
  grunt.registerTask 'prep_release', ['build', 'dom_munger:latest_version', 'zip:chosen','package_jquery']

  grunt.registerTask 'package_jquery', 'Generate a jquery.json manifest file from package.json', () ->
    src = "package.json"
    dest = "chosen.jquery.json"
    pkg = grunt.file.readJSON(src)
    json1 =
      "name": pkg.name
      "description": pkg.description
      "version": version()
      "licenses": pkg.licenses
    json2 = pkg.jqueryJSON
    json1[key] = json2[key] for key of json2
    json1.author.name = pkg.author
    grunt.file.write('chosen.jquery.json', JSON.stringify(json1, null, 2))
  
  grunt.registerTask('dev', ['default', 'connect', 'watch']);