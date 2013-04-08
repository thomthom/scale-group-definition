#-------------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-------------------------------------------------------------------------------

require 'sketchup.rb'
begin
  require 'TT_Lib2/core.rb'
rescue LoadError => e
  module TT
    if @lib2_update.nil?
      url = 'http://www.thomthom.net/software/sketchup/tt_lib2/errors/not-installed'
      options = {
        :dialog_title => 'TT_Lib² Not Installed',
        :scrollable => false, :resizable => false, :left => 200, :top => 200
      }
      w = UI::WebDialog.new( options )
      w.set_size( 500, 300 )
      w.set_url( "#{url}?plugin=#{File.basename( __FILE__ )}" )
      w.show
      @lib2_update = w
    end
  end
end


#-------------------------------------------------------------------------------

if defined?( TT::Lib ) && TT::Lib.compatible?( '2.7.0', 'Scale Group Definition' )

module TT::Plugins::ScaleGroupDefinition
  
  
  ### CONSTANTS ### ------------------------------------------------------------
  
  # Plugin information
  PLUGIN          = self
  PLUGIN_ID       = 'TT_ScaleGroupDefinition'.freeze
  PLUGIN_NAME     = 'Scale Group Definition'.freeze
  PLUGIN_VERSION  = TT::Version.new(1,0,0).freeze
  
  # Version information
  RELEASE_DATE    = '22 Feb 13'.freeze
  
  # Feature detection
  SUPPORT_MENU_POSITION = Sketchup::Menu.instance_method(:add_item).arity != 1
  
  ### MENU & TOOLBARS ### ------------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    # Commands
    cmd = UI::Command.new( 'Scale Definition' ) {
      self.scale_group_definition
    }
    cmd.set_validation_proc {
      ( self.selected_group_scaled? ) ? MF_ENABLED : ( MF_DISABLED | MF_GRAYED )
    }
    cmd.status_bar_text = 'Apply the group scale to the definition.'
    cmd.tooltip = "Scale Group Definition"
    @cmd_scale_group_definition = cmd

    UI.add_context_menu_handler { |context_menu|
      self.build_context_menu( context_menu )
    }
  end 
  
  
  ### LIB FREDO UPDATER ### ----------------------------------------------------
  
  # @return [Hash]
  # @since 1.0.0
  def self.register_plugin_for_LibFredo6
    {   
      :name => PLUGIN_NAME,
      :author => 'thomthom',
      :version => PLUGIN_VERSION.to_s,
      :date => RELEASE_DATE,   
      :description => 'Adds a Scale Definition feature for Groups.',
      :link_info => 'http://sketchucation.com/forums/viewtopic.php?t=50811'
    }
  end
  
  
  ### MAIN SCRIPT ### ----------------------------------------------------------
  
  # @since 1.0.0
  def self.scale_group_definition
    model = Sketchup.active_model
    group = model.selection[0]

    tr = group.transformation
    x_scale = X_AXIS.transform( tr ).length
    y_scale = Y_AXIS.transform( tr ).length
    z_scale = Z_AXIS.transform( tr ).length

    tr_definition = Geom::Transformation.scaling( x_scale, y_scale, z_scale )
    tr_instance = tr_definition.inverse

    TT::Model.start_operation( 'Scale Definition' )

    definition = TT::Instance.definition( group )
    entities = definition.entities
    entities.transform_entities( tr_definition, entities.to_a )

    for instance in definition.instances
      tr_i = instance.transformation
      instance.transform!( tr_i * tr_instance * tr_i.inverse )
    end

    model.commit_operation
  end


  # @since 1.0.0
  def self.build_context_menu( context_menu )
    if self.group_selected?
      if SUPPORT_MENU_POSITION
        context_menu.add_item( @cmd_scale_group_definition, 11 )
      else
        context_menu.add_item( @cmd_scale_group_definition )
      end
    end
  end


  # @since 1.0.0
  def self.group_selected?
    selection = Sketchup.active_model.selection
    selection.length == 1 && selection[0].is_a?( Sketchup::Group )
  end


  # @since 1.0.0
  def self.selected_group_scaled?
    group = Sketchup.active_model.selection[0]
    tr = group.transformation
    x_scale = X_AXIS.transform( tr ).length
    y_scale = Y_AXIS.transform( tr ).length
    z_scale = Z_AXIS.transform( tr ).length
    unit = 1.to_l
    !( x_scale == unit && y_scale == unit && z_scale == unit )
  end

  
  ### DEBUG ### ----------------------------------------------------------------
  
  # @note Debug method to reload the plugin.
  #
  # @example
  #   TT::Plugins::ScaleGroupDefinition.reload
  #
  # @param [Boolean] tt_lib Reloads TT_Lib2 if +true+.
  #
  # @return [Integer] Number of files reloaded.
  # @since 1.0.0
  def self.reload( tt_lib = false )
    original_verbose = $VERBOSE
    $VERBOSE = nil
    TT::Lib.reload if tt_lib
    # Core file (this)
    load __FILE__
    # Supporting files
    if defined?( PATH ) && File.exist?( PATH )
      x = Dir.glob( File.join(PATH, '*.{rb,rbs}') ).each { |file|
        load file
      }
      x.length + 1
    else
      1
    end
  ensure
    $VERBOSE = original_verbose
  end

end # module

end # if TT_Lib

#-------------------------------------------------------------------------------

file_loaded( __FILE__ )

#-------------------------------------------------------------------------------