(function($){
	$.fn.extend({
	    /* Scroll something - jQuery plugin
	     * 
	     * The perfect solution if you desperatly need to scroll something. You can
	     * scroll anything you want.
	     * 
	     * How to use:
	     * $("#myScrollebleItems").scrollSomething();
	     * 
	     * The options:
	     * scrollerWidth   = The width of the scroller.
	     * scrollerHeight  = The height of the scroller
	     * itemsVisable    = Number of items that are visable in the scroller
	     * itemsScrolling  = Number of items that scroll at the same time
	     * scrollInterval  = Set time (miliseconds) to activate automatoc scrolling
	     * scrollAnimation = Time between scrolling starts and stops
	     * scrollRewind    = Time to scroll back to item 1
	     * scrollPrefix    = Prefix for some classes (multiple scrollers on 1 page)
	     * buttonSettings  = Button settings: "hide" (no buttons), "show" (always
	     *                   visable) or "hover" (visable when hovering the scroller)
	     * buttonPosition  = Position of the buttons: "topLeft", "topRight",
	     *                   "bottomLeft" or "bottomRight"
	     * 
	     * To add a backround image to an item, you only have to put an image in the
	     * item. Just give the image a class called "itemBackground". And if you want
	     * a highlight for the text, add "wrapLight" or "wrapDark" as a class to the
	     * item.
	     * 
	     * If you want to add a link to the scroll item, just add an anchor tag to the
	     * item and give it a class called "itemLink".
	     * 
	     * Developed with jQuery version: 1.4.2
	     * 
	     * Version: 1.0.0
	     * Name: scrollSomething
	     * 
	     * Author: S.C. Tijdeman
	     * E-mail: senne@howardshome.com
	     */
	    
		scrollSomething: function(custom_settings) {
            // default settings
            var defaults = {
                scrollerWidth: 668,
                scrollerHeight: 55,
                itemsVisable: 1,
                itemsScrolling: 1,
                scrollInterval: 0,
                scrollAnimation: 1000,
                scrollRewind: 2500,
                scrollPrefix: "scroll",
                buttonSettings: "hover",
                buttonPosition: "bottomRight"
            };
            
            var settings = $.extend(defaults, custom_settings);
            
            return this.each(function() {
            
                var obj = $(this);
                
                // Wrap several elements around the object and add a class to the obj
                obj.addClass(""+ settings.scrollPrefix +"scroller");
                obj.wrap("<div class=\""+ settings.scrollPrefix +"scrollerWrapper scrollerWrapper\" />")
                   .wrap("<div class=\""+ settings.scrollPrefix +"scrollerScroller scrollerScroller\" />")
                   .wrap("<div class=\""+ settings.scrollPrefix +"scrollerHolder\" />");
                
                // Add some css to the scroller
                $("."+ settings.scrollPrefix +"scroller").css("margin", 0)
                                                         .css("padding", 0);
                
                // Add some css to the wrapper
                $("."+ settings.scrollPrefix +"scrollerWrapper").css("width", "440px")
                                                                .css("height", "55px");
                
                // Add some css to the scroller
                $("."+ settings.scrollPrefix +"scrollerScroller").css("width", "430px")
                                                                 .css("height", "55px");
                
                // Add button wrapper
                $("."+ settings.scrollPrefix +"scrollerWrapper").append("<div class=\""+ settings.scrollPrefix +"scrollerButtons scrollerButtons\" />");
                
                // Add buttons
                $("."+ settings.scrollPrefix +"scrollerButtons").append("<div class=\""+ settings.scrollPrefix +"scrollerNext scrollerNext\" />")
                                                                .append("<div class=\""+ settings.scrollPrefix +"scrollerPrev scrollerPrev\" />");
                
                // Set the position of the buttons
                var buttonPos_1, buttonPos_2;
                    
                if(settings.buttonPosition == "topLeft"){
                    buttonPos_1 = "top"; buttonPos_2 = "left";
                    
                    leftCorrection = 30; rightCorrection = 0;
                }else if(settings.buttonPosition == "topRight"){
                    buttonPos_1 = "top"; buttonPos_2 = "right";
                    
                    leftCorrection = 0; rightCorrection = 30;
                }else if(settings.buttonPosition == "bottomLeft"){
                    buttonPos_1 = "bottom"; buttonPos_2 = "left";
                    
                    leftCorrection = 30; rightCorrection = 0;
                }else if(settings.buttonPosition == "bottomRight"){
                    buttonPos_1 = "right"; buttonPos_2 = "bottom";
                    
                    leftCorrection = 0; rightCorrection = 0; bottomCorrection = 26;
                };
                
                $("."+ settings.scrollPrefix +"scrollerNext").css(buttonPos_1, 4 +"px")
                                                             .css(buttonPos_2, 8 + leftCorrection +"px");
                $("."+ settings.scrollPrefix +"scrollerPrev").css(buttonPos_1, 4 +"px")
                                                             .css(buttonPos_2, 5 + bottomCorrection +"px");
                
                // Add some css to the ul
                var slideWidth = settings.scrollerWidth / settings.itemsVisable;
                $("."+ settings.scrollPrefix +"scroller > *").css("width", "205px")
                                                             .css("height", settings.scrollerHeight +"px")
                                                             .css("float", "left")
                                                             .css("display", "block");
                
                // Start the code
                var totalSlides   = 0,
                    currentSlide  = 1,
                    contentSlides = "",
                    scrollStatus  = "normal";
                
                $(document).ready(function(){
                    $("."+ settings.scrollPrefix +"scrollerPrev").click(showPreviousSlide);
                    $("."+ settings.scrollPrefix +"scrollerNext").click(showNextSlide);

                    var totalWidth = 0;
                    contentSlides = $("."+ settings.scrollPrefix +"scroller > *");
                    
                    contentSlides.each(function(i){
                        totalWidth += this.clientWidth;
                        totalSlides++;
                        
                        var itemBackground  = $(this).find(".itemBackground").attr("src"),
                            backgroundClass = $(this).find(".itemBackground").attr("class"),
                            wrapStyle       = $(this).attr("class");
                        
                        var itemStr = "<div class=\""+ settings.scrollPrefix +"itemTextWrapper_"+ i +"\"><div class=\""+ settings.scrollPrefix +"itemText_"+ i +"\">"+ $(this).html() +"</div></div>";
                        $(this).html(itemStr);
                        
                        if(backgroundClass == "itemBackground"){
                            $(this).css("background-image", "url("+ itemBackground +")")
                                   .css("background-repeat", "no-repeat");
                        }
                        
                        if(wrapStyle == "wrapDark" || wrapStyle == "wrapLight"){
                            $("."+ settings.scrollPrefix +"itemTextWrapper_"+ i).css("display", "block")
                                                     .css("position", "absolute")
                                                     .css("width", slideWidth +"px")
                                                     .css("min-height", "32px")
                                                     .css("bottom", "0");
                            
                            $("."+ settings.scrollPrefix +"itemText_"+ i).css("padding", "5px")
                                              .css("font-size", "0.9em")
                                              .css("line-height", "0.9em");
                            
                            if(wrapStyle == "wrapDark"){
                                $("."+ settings.scrollPrefix +"itemTextWrapper_"+ i).css("background", "black")
                                                         .css("color", "white")
                                                         .fadeTo("fast", 0.75);
                            }else if(wrapStyle == "wrapLight"){
                                $("."+ settings.scrollPrefix +"itemTextWrapper_"+ i).css("background", "white")
                                                         .css("color", "black")
                                                         .fadeTo("fast", 0.75);
                            }
                        }
                        
                        var itemLink   = $(this).find(".itemLink").attr("href"),
                            linkClass  = $(this).find(".itemLink").attr("class");
                        
                        if(linkClass == "itemLink"){
                            $(this).css("cursor", "hand")
                                   .css("cursor", "pointer");
                            
                            $(this).click(function(){
                                window.open(itemLink);
                            });
                        }
                    });
                    
                    $("."+ settings.scrollPrefix +"scrollerHolder").width(totalWidth);
                    $("."+ settings.scrollPrefix +"scrollerScroller").attr({scrollLeft: 0});
                    
                    if(settings.buttonSettings == "hover" || settings.buttonSettings == "hide"){
                        $("."+ settings.scrollPrefix +"scrollerButtons").hide();
                    }
                    
                    $("."+ settings.scrollPrefix +"scrollerWrapper").mouseenter(function(){
                        if(settings.buttonSettings == "hover"){
                            $("."+ settings.scrollPrefix +"scrollerButtons").show();
                        }
                        
                        if(scrollStatus == "normal"){
                            scrollStatus = "pause";
                        } else if(scrollStatus == "end"){
                            scrollStatus = "endpause";
                        }
                    }).mouseleave(function(){
                        if(settings.buttonSettings == "hover"){
                            $("."+ settings.scrollPrefix +"scrollerButtons").hide();
                        }
                        
                        if(scrollStatus == "pause"){
                            scrollStatus = "normal";
                        } else if(scrollStatus == "endpause"){
                            scrollStatus = "end";
                        }
                    });
                    
                    updateButtons();
                    
                    if(settings.scrollInterval > 0){
                        setTimeout(intervalSwitch, settings.scrollInterval);
                    }
                });
                
                function showPreviousSlide()
                {
                    scrollStatus = "click";
                    
                    currentSlide = currentSlide - settings.itemsScrolling;
                    
                    updateContentHolder();
                    updateButtons();
                }
                
                function showNextSlide()
                {
                    scrollStatus = "click";
                    
                    currentSlide = currentSlide + settings.itemsScrolling;
                    
                    updateContentHolder();
                    updateButtons();
                }
                
                function updateContentHolder()
                {
                    var scrollAmount = 0;
                    
                    contentSlides.each(function(i){
                        if(currentSlide - 1 > i) {
                            scrollAmount += this.clientWidth;
                        }
                    });
                    
                    $("."+ settings.scrollPrefix +"scrollerScroller").animate({scrollLeft: scrollAmount}, settings.scrollAnimation);
                }
                
                function rewindContentHolder()
                {
                    $("."+ settings.scrollPrefix +"scrollerScroller").animate({scrollLeft: 0}, settings.scrollRewind);
                    
                    currentSlide = 1;
                    scrollStatus = "normal";
                    updateButtons();
                    
                    if(settings.scrollInterval > 0){
                        setTimeout(intervalSwitch, (settings.scrollInterval + settings.scrollRewind));
                    }
                }
                
                function updateButtons()
                {
                    totalSlidesTest = totalSlides - settings.itemsVisable + 1;
                    
                    if(currentSlide < totalSlidesTest) {
                        $("."+ settings.scrollPrefix +"scrollerNext").show();
                    } else {
                        scrollStatus = "end";
                        
                        $("."+ settings.scrollPrefix +"scrollerNext").hide();
                    }
                    
                    if(currentSlide > 1) {
                        $("."+ settings.scrollPrefix +"scrollerPrev").show();
                    } else {
                        $("."+ settings.scrollPrefix +"scrollerPrev").hide();
                    }
                }
                
                function intervalSwitch()
                {
                    if(scrollStatus == "normal"){
                        currentSlide = currentSlide + settings.itemsScrolling;
                        
                        updateContentHolder();
                        updateButtons();
                        
                        setTimeout(intervalSwitch, (settings.scrollInterval + settings.scrollAnimation));
                    } else if(scrollStatus == "pause") {
                        setTimeout(intervalSwitch, settings.scrollInterval);
                    } else if(scrollStatus == "click") {
                        scrollStatus = "normal";
                        setTimeout(intervalSwitch, settings.scrollInterval);
                    } else if(scrollStatus == "end") {
                        rewindContentHolder();
                    }
                }
            });
        }
	});
})(jQuery);