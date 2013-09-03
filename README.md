# Chosen

Chosen is a library for making long, unwieldy select boxes more user friendly.

- jQuery support: 1.4+

For **documentation**, usage, and examples, see:  
http://harvesthq.github.io/chosen/

For **downloads**, see:  
https://github.com/harvesthq/chosen/releases/

### Fork Changes

* Support for loading data from sources other than the OPTION tags. The aim is 
  to allow chosen to be used as an autocomplete widget.
  Similar to the jQuery autocomplete source option, a source can be:
  * An array of objects
  * A function
  * A URL

* Support for rendering "scopes" in single select mode. The aim was to allow chosen
  to be used a hierarchical select.
  
* IE 7 is turned on. Note that you need to patch your CSS for IE7 to work.

* Support for being within an `overflow:hidden` element. I basically merged and
  tweaked https://github.com/gil/chosen.
  
* Prototype does not work.

### Contributing to this project

We welcome all to participate in making Chosen the best software it can be. The repository is maintained by only a few people, but has accepted contributions from over 50 authors after reviewing hundreds of pull requests related to thousands of issues. You can help reduce the maintainers' workload (and increase your chance of having an accepted contribution to Chosen) by following the
[guidelines for contributing](contributing.md).

* [Bug reports](contributing.md#bugs)
* [Feature requests](contributing.md#features)
* [Pull requests](contributing.md#pull-requests)

### Chosen Credits

- Concept and development by [Patrick Filler](http://patrickfiller.com) for [Harvest](http://getharvest.com/).
- Design and CSS by [Matthew Lettini](http://matthewlettini.com/)
- Repository maintained by [@pfiller](http://github.com/pfiller), [@kenearley](http://github.com/kenearley), [@stof](http://github.com/stof) and [@koenpunt](http://github.com/koenpunt).
- Chosen includes [contributions by many fine folks](https://github.com/harvesthq/chosen/contributors).
