function nextSlide()
{
    var slides = document.getElementsByClassName("currentSlide");
    var cur = slides[0];

    // for great defensiveness
    for (var i = 1; i < slides.length; i++)
        slides[i].classList.remove("currentSlide");

    var next = cur.getUserData("nextSlide");
    if (next) {
        cur.classList.remove("currentSlide");
        next.classList.add("currentSlide");
        document.location.hash = "#" + next.id;
    }
}

function prevSlide()
{
    var slides = document.getElementsByClassName("currentSlide");
    var cur = slides[0];

    // for great defensiveness
    for (var i = 1; i < slides.length; i++)
        slides[i].classList.remove("currentSlide");

    var prev = cur.getUserData("prevSlide");
    if (prev) {
        cur.classList.remove("currentSlide");
        prev.classList.add("currentSlide");
        document.location.hash = "#" + prev.id;
    }
}

function clickEvent(event)
{
    nextSlide();
    event.stopPropagation();
    event.preventDefault();
}

function keyEvent(event)
{
    var slide = document.getElementById("currentSlide");
    switch (event.keyCode) {
    case 13:  /* return */
    case 32:  /* space */
    case 39:  /* right arrow */
    case 40:  /* down arrow */
        nextSlide();
        break;

    case 8:   /* backspace */
    case 37:  /* left arrow */
    case 38:  /* up arrow */
        prevSlide();
        break;
    }
    event.stopPropagation();
    event.preventDefault();
}

function rewriteSlideDOM(slide, index, count)
{
    var head, content, foot, child, sib, n, s, slideNo, slideNoText;

    for (child = slide.firstChild; child !== null; child = sib) {
        sib = child.nextSibling;
        slide.removeChild(child);
        if (child.nodeType !== 1 /* element */) {
            if (child.nodeType == 3 /* text */ && !/\S/.test(child.textContent))
                continue; /* discard text nodes consisting entirely of
                             whitespace */
            if (!content) {
                content = document.createElement("div");
                content.className = "content";
            }
            content.appendChild(child);
        }

        switch (child.tagName) {
        case "HEADER":
            if (head) {
                n = child.firstChild;
                while (n) {
                    s = n.nextSibling;
                    child.removeChild(n);
                    head.appendChild(n);
                    s = n;
                }
            } else {
                head = child;
            }
            break;

        case "HGROUP":
        case "H1":
        case "H2":
        case "H3":
        case "H4":
        case "H5":
        case "H6":
            if (!head) {
                head = document.createElement("header");
            }
            head.appendChild(child);
            break;

        case "FOOTER":
            if (foot) {
                n = child.firstChild;
                while (n) {
                    s = n.nextSibling;
                    child.removeChild(n);
                    foot.appendChild(n);
                    s = n;
                }
            } else {
                foot = child;
            }
            break;

        default:
            if (!content) {
                content = document.createElement("div");
                content.className = "content";
            }
            content.appendChild(child);
        }
    }

    if (!head)
        head = document.createElement("header");
    if (!foot)
        foot = document.createElement("footer");
    if (!content) {
        content = document.createElement("div");
        content.className = "content";
    }

    slideNoText = document.createTextNode("" + index + " / " + count);
    slideNo = document.createElement("div");
    slideNo.className = "slideNumber";
    slideNo.appendChild(slideNoText);
    foot.appendChild(slideNo);

    slide.appendChild(head);
    slide.appendChild(content);
    slide.appendChild(foot);

    if (slide.id === undefined || slide.id === null || slide.id === "")
        slide.id = "slide-" + index;
}

window.onload = function onload()
{
    var slides = document.getElementsByTagName('section');
    var i;

    for (i = 0; i < slides.length; i++) {
        rewriteSlideDOM(slides[i], i+1, slides.length);

        slides[i].setUserData("prevSlide",
                              (i == 0) ? null : slides[i-1],
                              null);

        slides[i].setUserData("nextSlide",
                              (i == slides.length) ? null : slides[i+1],
                              null);
    }

    if (document.location.hash) {
        var target = document.getElementById(document.location.hash.slice(1));
        while (target
               && target !== document
               && target.tagName !== "SECTION")
            target = target.parentNode;
        if (target && target.tagName === "SECTION")
            target.classList.add("currentSlide");
        else {
            slides[0].classList.add("currentSlide");
            document.location.hash = "#" + slides[0].id;
        }
    } else {
        slides[0].classList.add("currentSlide");
        document.location.hash = "#" + slides[0].id;
    }

    /*window.addEventListener("click", clickEvent);*/
    window.addEventListener("keyup", keyEvent);
};

/* todo:
   menu
   goto
   hash
   slide numbers
   generic footer and header support?
*/