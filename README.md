ActionController-ActionView interactions
==========================

This is part of Police, an MIT CSAIL project. More information about it can be found here: https://github.com/csail/police.

Police requires hooking into many aspects of the Rails framework to secure applications through data-flow assertions. This document outlies the data-flow between Rails's `ActionController` and `ActionView`. It should be of use to anyone interested in understanding how these two components relate. This is not about how to develop Rails applications.

There are a number of Rails components at work within this system:

* `AbstractController`
* `ActionController`
* `ActionController::Metal`
* `ActionView`

Not all of these require going into great depth however. `AbstractController` outlies the basic functionality the controller should provide. `ActionController::Metal` inherits from this and provides the minimal level of code for it to interface with `Rack`. `ActionController` builds off of `::Metal` and adds nice things like caching and a proper middleware stack. 

The actual `ApplicationController` class a developer uses to establish their application builds off `ActionController`.

#### Initiating a controller from an incoming request

The controller establishes a number of endpoints for requests, based on the action names (functions like #index, #show, #new... etc)  within an application's controllers. `ActionController::Base` will find all of these endpoints, and when a request comes in to a particular one, it will call `ActionController::Base#dispatch` with the name of the action. This `#dispatch` call triggers all of the controller-view interactions.

#### Running controller function and preparing an ActionView

What's desired next is that the function will be run and its local variables will likely be substituted into a layout or template file. This aspect begins in `AbstractController::Renderer`. This module focuses on extracting the local variables from the requested function and preparing an `ActionView` instance that can then pull together the right layouts/templates/etc and render the content.

`AbstractController::Renderer#view_assigns` is an important function that grabs all of the local variables from the requested function.

`AbstractController::Renderer#view_context` grabs the local variables and an appropriate `ActionView::Renderer` object. The `ActionView::Renderer` pulled in depends on whether the content is HTML, JSON, XML, etc.

`AbstractController::Renderer#render_to_body` might be of interest for a developer looking to hook into the options sent to the template. It initially calls `#_process_options`, which can easily be wrapped and is designed for plugins.

`AbstractController::Renderer#_render_template` calls the `#render` function on the created `ActionView` instance. This is important! This is when the controller diverts to `ActionView` to do further processing.

#### ActionView rendering

Once the `ActionView#render` function has been called, all work moves to the `ActionView`. The `ActionView` created in the `AbstractController` has an `ActionView::Renderer` specific the content-type about to be returned. For most cases where variable substitution will occur, this will then divert to the `ActionView::Renderer::PartialRenderer` and `ActionView::Renderer::TemplateRenderer`.

The vast majority of `::TemplateRenderer` and `::PartialRenderer` is bookkeepping and fallback methods to find all of the template/layout/partial .erb files. Unless one specifically needs to modify this behavior, it's not particularly interesting.

Once the proper template files are sourced, `ActionView::Template#render` is called. This function grabs the template files and calls `#compile`, which will automagically generate functions to assign the local variables in an encoding-safe way. Once that is done, then it calls the appropriate handler (for `ERB`, text, etc.) to finish the call. All of the `ERB` processing is essentially hidden away in the included `Erubis` library. However, the `#compile` function still might be of interest for some, although it's not relevant for Police.

#### Returning the rendered content as a response

Once `ActionView` has finished rendering, the `String` it has produced is returned to the controller. It is assigned to `ActionController.response_body`.

At long last the rendering is complete, and `ActionController::Metal#dispatch` can finish its call and send off an `ActionDispatch` message to `Rack`.
