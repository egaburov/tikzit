/*
 * Copyright 2011  Alex Merry <alex.merry@kdemail.net>
 *
 * Stuff stolen from glade-window.c in Glade:
 *     Copyright (C) 2001 Ximian, Inc.
 *     Copyright (C) 2007 Vincent Geddes.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "Menu.h"

#import "Application.h"
#import "Window.h"
#import "Configuration.h"
#import "PickSupport.h"
#import "Shape.h"
#import "Tool.h"
#import "TikzDocument.h"

#import <glib.h>
#ifdef _
#undef _
#endif
#import <glib/gi18n.h>
#import <gtk/gtk.h>

#import "gtkhelpers.h"

#import "logo.h"

// {{{ Application actions
static void new_cb (GtkAction *action, Application *appl) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [appl newWindow];
    [pool drain];
}

static void refresh_shapes_cb (GtkAction *action, Application *appl) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [Shape refreshShapeDictionary];
    [pool drain];
}

static void show_preferences_cb (GtkAction *action, Application *appl) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [appl presentSettingsDialog];
    [pool drain];
}

#ifdef HAVE_POPPLER
static void show_preamble_cb (GtkAction *action, Application *appl) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [appl presentPreamblesEditor];
    [pool drain];
}
#endif

static void show_context_window_cb (GtkAction *action, Application *appl) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [appl presentContextWindow];
    [pool drain];
}

static void quit_cb (GtkAction *action, Application *appl) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [appl quit];
    [pool drain];
}

static void help_cb (GtkAction *action, Application *appl) {
    GError *gerror = NULL;
    gtk_show_uri (NULL, "http://tikzit.sourceforge.net/manual.html", GDK_CURRENT_TIME, &gerror);
    if (gerror != NULL) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        logGError (gerror, @"Could not show help");
        [pool drain];
    }
}

static void about_cb (GtkAction *action, Application *appl) {
    static const gchar * const authors[] =
        { "Aleks Kissinger <aleks0@gmail.com>",
          "Chris Heunen <chrisheunen@gmail.com>",
          "Alex Merry <dev@randomguy3.me.uk>",
          NULL };

    static const gchar license[] =
        N_("TikZiT is free software; you can redistribute it and/or modify "
          "it under the terms of the GNU General Public License as "
          "published by the Free Software Foundation; either version 2 of the "
          "License, or (at your option) any later version."
          "\n\n"
          "TikZiT is distributed in the hope that it will be useful, "
          "but WITHOUT ANY WARRANTY; without even the implied warranty of "
          "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "
          "GNU General Public License for more details."
          "\n\n"
          "You should have received a copy of the GNU General Public License "
          "along with TikZiT; if not, write to the Free Software "
          "Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, "
          "MA 02110-1301, USA.");

    static const gchar copyright[] =
        "Copyright \xc2\xa9 2010-2011 Aleks Kissinger, Chris Heunen and Alex Merry.";

    GdkPixbuf *logo = get_logo (LOGO_SIZE_128);
    gtk_show_about_dialog (NULL,
                   "program-name", PACKAGE_NAME,
                   "logo", logo,
                   "authors", authors,
                   "translator-credits", _("translator-credits"),
                   "comments", _("A graph manipulation program for pgf/tikz graphs"),
                   "license", _(license),
                   "wrap-license", TRUE,
                   "copyright", copyright,
                   "version", PACKAGE_VERSION,
                   "website", "http://tikzit.sourceforge.net",
                   NULL);
    g_object_unref (logo);
}

static GtkActionEntry app_action_entries[] = {
    /*
        Fields:
          * action name
          * stock id or name of icon for action
          * label for action (mark for translation with N_)
          * accelerator (as understood by gtk_accelerator_parse())
          * tooltip (mark for translation with N_)
          * callback
    */
    { "New", GTK_STOCK_NEW, NULL, "<control>N",
      N_("Create a new graph"), G_CALLBACK (new_cb) },

    { "RefreshShapes", NULL, N_("_Refresh shapes"), NULL,
      N_(""), G_CALLBACK (refresh_shapes_cb) },

    { "Quit", GTK_STOCK_QUIT, NULL, "<control>Q",
      N_("Quit the program"), G_CALLBACK (quit_cb) },

    { "Tool", NULL, N_("_Tool") },

    { "ShowPreferences", GTK_STOCK_PREFERENCES, N_("Configure TikZiT..."), NULL,
      N_("Edit the TikZiT configuration"), G_CALLBACK (show_preferences_cb) },

#ifdef HAVE_POPPLER
    { "ShowPreamble", NULL, N_("_Edit Preambles..."), NULL,
      N_("Edit the preambles used to generate the preview"), G_CALLBACK (show_preamble_cb) },
#endif

    { "ShowContextWindow", NULL, N_("_Context Window"), NULL,
      N_("Show the contextual tools window"), G_CALLBACK (show_context_window_cb) },

    /* HelpMenu */
    { "HelpManual", GTK_STOCK_HELP, N_("_Online manual"), "F1",
      N_("TikZiT manual (online)"), G_CALLBACK (help_cb) },

    { "About", GTK_STOCK_ABOUT, NULL, NULL,
      N_("About this application"), G_CALLBACK (about_cb) },
};
static guint n_app_action_entries = G_N_ELEMENTS (app_action_entries);
// }}}
// {{{ Window actions

static void open_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window openFile];
    [pool drain];
}

static void close_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window close];
    [pool drain];
}

static void save_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window saveActiveDocument];
    [pool drain];
}

static void save_as_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window saveActiveDocumentAs];
    [pool drain];
}

static void save_as_shape_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window saveActiveDocumentAsShape];
    [pool drain];
}

static void undo_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    TikzDocument *document = [window document];
    if ([document canUndo]) {
        [document undo];
    } else {
        g_warning ("Can't undo!\n");
        gtk_action_set_sensitive (action, FALSE);
    }

    [pool drain];
}

static void redo_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    TikzDocument *document = [window document];
    if ([document canRedo]) {
        [document redo];
    } else {
        g_warning ("Can't redo!\n");
        gtk_action_set_sensitive (action, FALSE);
    }

    [pool drain];
}

static void cut_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window selectionCutToClipboard];
    [pool drain];
}

static void copy_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window selectionCopyToClipboard];
    [pool drain];
}

static void paste_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window pasteFromClipboard];
    [pool drain];
}

static void delete_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] removeSelected];
    [pool drain];
}

static void select_all_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TikzDocument *document = [window document];
    [[document pickSupport] selectAllNodes:[NSSet setWithArray:[[document graph] nodes]]];
    [pool drain];
}

static void deselect_all_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TikzDocument *document = [window document];
    [[document pickSupport] deselectAllNodes];
    [[document pickSupport] deselectAllEdges];
    [pool drain];
}

static void flip_horiz_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] flipSelectedNodesHorizontally];
    [pool drain];
}

static void flip_vert_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] flipSelectedNodesVertically];
    [pool drain];
}

static void reverse_edges_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] reverseSelectedEdges];
    [pool drain];
}

static void bring_forward_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] bringSelectionForward];
    [pool drain];
}

static void send_backward_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] sendSelectionBackward];
    [pool drain];
}

static void bring_to_front_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] bringSelectionToFront];
    [pool drain];
}

static void send_to_back_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [[window document] sendSelectionToBack];
    [pool drain];
}

#ifdef HAVE_POPPLER
static void show_preview_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window presentPreview];
    [pool drain];
}
#endif

static void zoom_in_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window zoomIn];
    [pool drain];
}

static void zoom_out_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window zoomOut];
    [pool drain];
}

static void zoom_reset_cb (GtkAction *action, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [window zoomReset];
    [pool drain];
}

static void recent_chooser_item_activated_cb (GtkRecentChooser *chooser, Window *window) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    gchar *uri, *path;
    GError *error = NULL;

    uri = gtk_recent_chooser_get_current_uri (chooser);

    path = g_filename_from_uri (uri, NULL, NULL);
    if (error) {
        g_warning ("Could not convert uri \"%s\" to a local path: %s", uri, error->message);
        g_error_free (error);
        return;
    }

    [window openFileAtPath:[NSString stringWithGlibFilename:path]];

    g_free (uri);
    g_free (path);

    [pool drain];
}


static GtkActionEntry window_action_entries[] = {
    /*
        Fields:
          * action name
          * stock id or name of icon for action
          * label for action (mark for translation with N_)
          * accelerator (as understood by gtk_accelerator_parse())
          * tooltip (mark for translation with N_)
          * callback
    */
    { "FileMenu", NULL, N_("_File") },
    { "EditMenu", NULL, N_("_Edit") },
    { "ViewMenu", NULL, N_("_View") },
    { "HelpMenu", NULL, N_("_Help") },

    { "Arrange", NULL, N_("_Arrange") },
    { "Zoom", NULL, N_("_Zoom") },

    { "Open", GTK_STOCK_OPEN, N_("_Open\342\200\246") ,"<control>O",
      N_("Open a graph"), G_CALLBACK (open_cb) },

    { "Close", GTK_STOCK_CLOSE, NULL, "<control>W",
      N_("Close the current graph"), G_CALLBACK (close_cb) },

    { "ZoomIn", GTK_STOCK_ZOOM_IN, NULL, "<control>plus",
      NULL, G_CALLBACK (zoom_in_cb) },

    { "ZoomOut", GTK_STOCK_ZOOM_OUT, NULL, "<control>minus",
      NULL, G_CALLBACK (zoom_out_cb) },

    { "ZoomReset", GTK_STOCK_ZOOM_100, N_("_Reset zoom"), "<control>0",
      NULL, G_CALLBACK (zoom_reset_cb) },

    { "Save", GTK_STOCK_SAVE, NULL, "<control>S",
      N_("Save the current graph"), G_CALLBACK (save_cb) },

    { "SaveAs", GTK_STOCK_SAVE_AS, N_("Save _As\342\200\246"), NULL,
      N_("Save the current graph with a different name"), G_CALLBACK (save_as_cb) },

    { "SaveAsShape", NULL, N_("Save As S_hape\342\200\246"), NULL,
      N_("Save the current graph as a shape for use in styles"), G_CALLBACK (save_as_shape_cb) },

    { "Undo", GTK_STOCK_UNDO, NULL, "<control>Z",
      N_("Undo the last action"),   G_CALLBACK (undo_cb) },

    { "Redo", GTK_STOCK_REDO, NULL, "<shift><control>Z",
      N_("Redo the last action"),   G_CALLBACK (redo_cb) },

    { "Cut", GTK_STOCK_CUT, NULL, NULL,
      N_("Cut the selection"), G_CALLBACK (cut_cb) },

    { "Copy", GTK_STOCK_COPY, NULL, NULL,
      N_("Copy the selection"), G_CALLBACK (copy_cb) },

    { "Paste", GTK_STOCK_PASTE, NULL, NULL,
      N_("Paste the clipboard"), G_CALLBACK (paste_cb) },

    { "Delete", GTK_STOCK_DELETE, NULL, "Delete",
      N_("Delete the selection"), G_CALLBACK (delete_cb) },

    { "SelectAll", GTK_STOCK_SELECT_ALL, NULL, "<control>A",
      N_("Select all nodes on the graph"), G_CALLBACK (select_all_cb) },

    { "DeselectAll", NULL, N_("D_eselect all"), "<shift><control>A",
      N_("Deselect everything"), G_CALLBACK (deselect_all_cb) },

    { "FlipHoriz", NULL, N_("Flip nodes _horizonally"), NULL,
      N_("Flip the selected nodes horizontally"), G_CALLBACK (flip_horiz_cb) },

    { "FlipVert", NULL, N_("Flip nodes _vertically"), NULL,
      N_("Flip the selected nodes vertically"), G_CALLBACK (flip_vert_cb) },

    { "ReverseEdges", NULL, N_("Rever_se edges"), NULL,
      N_("Reverse the selected edges"), G_CALLBACK (reverse_edges_cb) },

    { "SendToBack", NULL, N_("Send to _back"), NULL,
      N_("Send the selected nodes and edges to the back of the graph"), G_CALLBACK (send_to_back_cb) },

    { "SendBackward", NULL, N_("Send b_ackward"), NULL,
      N_("Send the selected nodes and edges backward"), G_CALLBACK (send_backward_cb) },

    { "BringForward", NULL, N_("Bring f_orward"), NULL,
      N_("Bring the selected nodes and edges forward"), G_CALLBACK (bring_forward_cb) },

    { "BringToFront", NULL, N_("Bring to _front"), NULL,
      N_("Bring the selected nodes and edges to the front of the graph"), G_CALLBACK (bring_to_front_cb) },

    /* ViewMenu */
#ifdef HAVE_POPPLER
    { "ShowPreview", NULL, N_("_Preview"), "<control>L",
      N_("See the graph as it will look when rendered in LaTeX"), G_CALLBACK (show_preview_cb) },
#endif
};
static guint n_window_action_entries = G_N_ELEMENTS (window_action_entries);

// }}}
// {{{ UI XML

static const gchar ui_info[] =
"<ui>"
"  <menubar name='MenuBar'>"
"    <menu action='FileMenu'>"
"      <menuitem action='New'/>"
"      <menuitem action='Open'/>"
"      <menuitem action='OpenRecent'/>"
"      <separator/>"
"      <menuitem action='Save'/>"
"      <menuitem action='SaveAs'/>"
"      <separator/>"
"      <menuitem action='SaveAsShape'/>"
"      <menuitem action='RefreshShapes'/>"
"      <separator/>"
"      <menuitem action='Close'/>"
"      <menuitem action='Quit'/>"
"    </menu>"
"    <menu action='EditMenu'>"
"      <menu action='Tool'>"
"      </menu>"
"      <separator/>"
"      <menuitem action='Undo'/>"
"      <menuitem action='Redo'/>"
"      <separator/>"
"      <menuitem action='Cut'/>"
"      <menuitem action='Copy'/>"
"      <menuitem action='Paste'/>"
"      <menuitem action='Delete'/>"
"      <separator/>"
"      <menuitem action='SelectAll'/>"
"      <menuitem action='DeselectAll'/>"
"      <separator/>"
"      <menuitem action='FlipVert'/>"
"      <menuitem action='FlipHoriz'/>"
"      <menuitem action='ReverseEdges'/>"
"      <separator/>"
"      <menu action='Arrange'>"
"        <menuitem action='SendToBack'/>"
"        <menuitem action='SendBackward'/>"
"        <menuitem action='BringForward'/>"
"        <menuitem action='BringToFront'/>"
"      </menu>"
"      <separator/>"
"      <menuitem action='ShowPreferences'/>"
"    </menu>"
"    <menu action='ViewMenu'>"
"      <menuitem action='ShowContextWindow'/>"
#ifdef HAVE_POPPLER
"      <menuitem action='ShowPreamble'/>"
"      <menuitem action='ShowPreview'/>"
#endif
"      <menu action='Zoom'>"
"        <menuitem action='ZoomIn'/>"
"        <menuitem action='ZoomOut'/>"
"        <menuitem action='ZoomReset'/>"
"      </menu>"
"    </menu>"
"    <menu action='HelpMenu'>"
"      <menuitem action='HelpManual'/>"
"      <separator/>"
"      <menuitem action='About'/>"
"    </menu>"
"  </menubar>"
/*
"  <toolbar  name='ToolBar'>"
"    <toolitem action='New'/>"
"    <toolitem action='Open'/>"
"    <toolitem action='Save'/>"
"    <separator/>"
"    <toolitem action='Cut'/>"
"    <toolitem action='Copy'/>"
"    <toolitem action='Paste'/>"
"    <separator/>"
"    <toolitem action='SelectMode'/>"
"    <toolitem action='CreateNodeMode'/>"
"    <toolitem action='DrawEdgeMode'/>"
"    <toolitem action='BoundingBoxMode'/>"
"    <toolitem action='HandMode'/>"
"  </toolbar>"
*/
"</ui>";



// }}}
// {{{ Helper methods

static void configure_recent_chooser (GtkRecentChooser *chooser)
{
    gtk_recent_chooser_set_local_only (chooser, TRUE);
    gtk_recent_chooser_set_show_icons (chooser, FALSE);
    gtk_recent_chooser_set_sort_type (chooser, GTK_RECENT_SORT_MRU);

    GtkRecentFilter *filter = gtk_recent_filter_new ();
    gtk_recent_filter_add_application (filter, g_get_application_name());
    gtk_recent_chooser_set_filter (chooser, filter);
}

static void tool_cb (GtkAction *action, id<Tool> tool) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [app setActiveTool:tool];
    [pool drain];
}



// }}}
// {{{ API

@implementation Menu

- (id) init {
    [self release];
    return nil;
}

- (id) initForWindow:(Window*)window {
    self = [super init];
    if (!self) {
        return nil;
    }

    GError *error = NULL;

    appActions = gtk_action_group_new ("TZApp");
    //gtk_action_group_set_translation_domain (actions, GETTEXT_PACKAGE);
    gtk_action_group_add_actions (appActions,
                      app_action_entries,
                      n_app_action_entries,
                      app);
    for (id<Tool> tool in [app tools]) {
        NSString *tooltip = [NSString stringWithFormat:
            @"%@: %@ (%@)", [tool name], [tool helpText], [tool shortcut]];
        GtkAction *action = gtk_action_new (
                [[tool name] UTF8String],
                [[tool name] UTF8String],
                [tooltip UTF8String],
                [tool stockId]);
        gtk_action_group_add_action_with_accel (
                appActions,
                action,
                NULL);
        g_signal_connect (
                G_OBJECT (action),
                "activate",
                G_CALLBACK (tool_cb),
                tool);
        g_object_unref (action);
    }

    windowActions = gtk_action_group_new ("TZWindow");
    //gtk_action_group_set_translation_domain (windowActions, GETTEXT_PACKAGE);

    gtk_action_group_add_actions (windowActions,
                      window_action_entries,
                      n_window_action_entries,
                      window);

    GtkAction *action = gtk_recent_action_new ("OpenRecent", N_("Open _Recent"), NULL, NULL);
    g_signal_connect (G_OBJECT (action),
            "item-activated",
            G_CALLBACK (recent_chooser_item_activated_cb),
            window);
    configure_recent_chooser (GTK_RECENT_CHOOSER (action));
    gtk_action_group_add_action_with_accel (windowActions, action, NULL);
    g_object_unref (action);

    /* Save refs to actions that will need to be updated */
    undoAction = gtk_action_group_get_action (windowActions, "Undo");
    redoAction = gtk_action_group_get_action (windowActions, "Redo");
    pasteAction = gtk_action_group_get_action (windowActions, "Paste");

    nodeSelBasedActionCount = 4;
    nodeSelBasedActions = g_new (GtkAction*, nodeSelBasedActionCount);
    nodeSelBasedActions[0] = gtk_action_group_get_action (windowActions, "Cut");
    nodeSelBasedActions[1] = gtk_action_group_get_action (windowActions, "Copy");
    nodeSelBasedActions[2] = gtk_action_group_get_action (windowActions, "FlipHoriz");
    nodeSelBasedActions[3] = gtk_action_group_get_action (windowActions, "FlipVert");
    edgeSelBasedActionCount = 1;
    edgeSelBasedActions = g_new (GtkAction*, edgeSelBasedActionCount);
    edgeSelBasedActions[0] = gtk_action_group_get_action (windowActions, "ReverseEdges");
    selBasedActionCount = 2;
    selBasedActions = g_new (GtkAction*, selBasedActionCount);
    selBasedActions[0] = gtk_action_group_get_action (windowActions, "Delete");
    selBasedActions[1] = gtk_action_group_get_action (windowActions, "DeselectAll");


    GtkUIManager *ui = gtk_ui_manager_new ();
    gtk_ui_manager_insert_action_group (ui, windowActions, 0);
    gtk_ui_manager_insert_action_group (ui, appActions, 1);
    gtk_window_add_accel_group ([window gtkWindow], gtk_ui_manager_get_accel_group (ui));
    if (!gtk_ui_manager_add_ui_from_string (ui, ui_info, -1, &error))
    {
        g_message ("Building menus failed: %s", error->message);
        g_error_free (error);
        g_object_unref (ui);
        [self release];
        return nil;
    }
    guint tool_merge_id = gtk_ui_manager_new_merge_id (ui);
    for (id<Tool> tool in [app tools]) {
        gtk_ui_manager_add_ui (ui,
                tool_merge_id,
                "/ui/MenuBar/EditMenu/Tool",
                [[tool name] UTF8String],
                [[tool name] UTF8String],
                GTK_UI_MANAGER_AUTO,
                FALSE);
    }
    menubar = gtk_ui_manager_get_widget (ui, "/MenuBar");
    g_object_ref_sink (menubar);
    g_object_unref (ui);

    return self;
}

- (void) dealloc {
    g_free (nodeSelBasedActions);
    g_free (edgeSelBasedActions);
    g_free (selBasedActions);
    g_object_unref (menubar);
    g_object_unref (appActions);
    g_object_unref (windowActions);

    [super dealloc];
}

@synthesize menubar;

- (void) setUndoActionEnabled:(BOOL)enabled {
    gtk_action_set_sensitive (undoAction, enabled);
}

- (void) setUndoActionDetail:(NSString*)detail {
    gtk_action_set_detailed_label (undoAction, "_Undo", [detail UTF8String]);
}

- (void) setRedoActionEnabled:(BOOL)enabled {
    gtk_action_set_sensitive (redoAction, enabled);
}

- (void) setRedoActionDetail:(NSString*)detail {
    gtk_action_set_detailed_label (redoAction, "_Redo", [detail UTF8String]);
}

- (GtkAction*) pasteAction {
    return pasteAction;
}

- (void) notifySelectionChanged:(PickSupport*)pickSupport {
    BOOL hasSelectedNodes = [[pickSupport selectedNodes] count] > 0;
    BOOL hasSelectedEdges = [[pickSupport selectedEdges] count] > 0;
    for (int i = 0; i < nodeSelBasedActionCount; ++i) {
        if (nodeSelBasedActions[i]) {
            gtk_action_set_sensitive (nodeSelBasedActions[i], hasSelectedNodes);
        }
    }
    for (int i = 0; i < edgeSelBasedActionCount; ++i) {
        if (edgeSelBasedActions[i]) {
            gtk_action_set_sensitive (edgeSelBasedActions[i], hasSelectedEdges);
        }
    }
    for (int i = 0; i < selBasedActionCount; ++i) {
        if (selBasedActions[i]) {
            gtk_action_set_sensitive (selBasedActions[i], hasSelectedNodes || hasSelectedEdges);
        }
    }
}

@end

// }}}

// vim:ft=objc:ts=8:et:sts=4:sw=4:foldmethod=marker
