define [
  'i18n!assignments'
  'compiled/views/KeyboardNavDialog'
  'jst/KeyboardNavDialog'
  'jquery'
  'underscore'
  'Backbone'
  'jst/assignments/IndexView'
  'jst/assignments/NoAssignmentsSearch'
  'compiled/views/assignments/AssignmentKeyBindingsMixin'
], (I18n, KeyboardNavDialog, keyboardNavTemplate, $, _, Backbone, template, NoAssignments, AssignmentKeyBindingsMixin) ->

  class IndexView extends Backbone.View
    @mixin AssignmentKeyBindingsMixin

    template: template
    el: '#content'

    @child 'assignmentGroupsView', '[data-view=assignmentGroups]'
    @child 'createGroupView', '[data-view=createGroup]'
    @child 'assignmentSettingsView', '[data-view=assignmentSettings]'
    @child 'showByView', '[data-view=showBy]'

    events:
      'keyup #search_term': 'search'

    els:
      '#addGroup': '$addGroupButton'
      '#assignmentSettingsCog': '$assignmentSettingsButton'

    initialize: ->
      super
      @collection.once 'reset', @enableSearch, @
      @collection.on 'cancelSearch', @clearSearch, @

    toJSON: ->
      json = super
      json.course_home = ENV.COURSE_HOME
      json

    afterRender: ->
      # need to hide child views and set trigger manually

      if @createGroupView
        @createGroupView.hide()
        @createGroupView.setTrigger @$addGroupButton

      if @assignmentSettingsView
        @assignmentSettingsView.hide()
        @assignmentSettingsView.setTrigger @$assignmentSettingsButton

      @filterKeyBindings() if @userIsStudent()

      @ensureContentStyle()

      @kbDialog = new KeyboardNavDialog().render(keyboardNavTemplate({keyBindings:@keyBindings}))
      window.onkeydown = @focusOnAssignments

    enableSearch: ->
      @$('#search_term').prop 'disabled', false

    clearSearch: ->
      @$('#search_term').val('')
      @filterResults()

    search: _.debounce ->
      @filterResults()
    , 200

    filterResults: =>
      term = $('#search_term').val()
      if term == ""
        #show all
        @collection.each (group) =>
          group.groupView.endSearch()

        #remove noAssignments placeholder
        if @noAssignments?
          @noAssignments.remove()
          @noAssignments = null
      else
        regex = new RegExp(@cleanSearchTerm(term), 'ig')
        #search
        atleastoneGroup = false
        @collection.each (group) =>
          atleastoneGroup = true if group.groupView.search(regex)

        #add noAssignments placeholder
        if !atleastoneGroup
          unless @noAssignments
            @noAssignments = new Backbone.View
              template: NoAssignments
              tagName: "li"
              className: "item-group-condensed"
            ul = @assignmentGroupsView.$el.children(".collectionViewItems")
            ul.append(@noAssignments.render().el)
        else
          #remove noAssignments placeholder
          if @noAssignments?
            @noAssignments.remove()
            @noAssignments = null

    cleanSearchTerm: (text) ->
      text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")

    focusOnAssignments: (e) =>
      if 74 == e.keyCode
        unless($(e.target).is("input"))
          $(".assignment_group").filter(":visible").first().attr("tabindex",-1).focus()

    userIsStudent: ->
      _.include(ENV.current_user_roles, "student")

    ensureContentStyle: ->
      # when loaded from homepage, need to change content style
      if window.location.href.indexOf('assignments') == -1
        $("#content").css("padding", "0em")

    filterKeyBindings: =>
      @keyBindings = @keyBindings.filter (binding) ->
        ! _.contains([69,68,65], binding.keyCode)
