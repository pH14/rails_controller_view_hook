# Here we wrap two functions. 
#
# The dispatch call is the last function of
# the controller to handle a request, so it has the complete HTML
# response.
#
# The view_assigns function initially grabs all of the local variables
# for a call before the rendering phase.
module ActionController
  class Metal
    old_dispatch = instance_method(:dispatch)

    define_method(:dispatch) do |*arg|
      # Call the original function
      dispatch_value = old_dispatch.bind(self).call(*arg)

      # dispatch_value[2].body nows contains all of the HTML after
      # rendering variables / tags / etc. It is of type String.
      unless PoliceFilter.check_policy(v)
         # Fail vigorously and with abundant error messages
      end
      
      # Return original values
      dispatch_value
    end

  end
end

module AbstractController
  module Rendering
    old_view_assigns = instance_method(:view_assigns)

    define_method(:view_assigns) do
      # Call the original view_assigns
      hash = old_view_assigns.bind(self).()

      # Here we can iterate over them and see if any policies are
      # not working right before we render anything. This would be
      # a good place to throw warnings, since it's not necessarily
      # true that each of these variables will actually be rendered.
      unless Rails.env.production?
        hash.each do |k, v|
          PoliceFilter.check_policy(v)
        end
      end

      # Return original values
      hash
    end
  end
end
