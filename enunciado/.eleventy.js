const syntaxHighlight = require("@11ty/eleventy-plugin-syntaxhighlight");

module.exports = function(eleventyConfig) {

    eleventyConfig.addPassthroughCopy("css");
    eleventyConfig.addPassthroughCopy("vendor");
    eleventyConfig.addPassthroughCopy("img");

    eleventyConfig.addPlugin(syntaxHighlight);
    
    eleventyConfig.addFilter("baseUrl", function(value) {
        if (value == "/") {
            return "./";
        }
        else {
            depth = value.split("/").length - 2;
            return "../".repeat(depth);
        }
    });
        
    return {
        dir: {
            output: "../docs"
        }
    }
};
