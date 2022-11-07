//
//  StoryListDetailView.swift
//  JottrDemo
//
//  Created by Kenneth Gutierrez on 10/7/22.
//

import Foundation
import SwiftUI

struct StoryListDetailView: View {
    // MARK: Properties
    
    // data stored in the Core Data
    let story: Story
    
    @StateObject var viewModel = StoryListDetailVM()
    
    // holds our openai text completion model
    @EnvironmentObject var txtComplVM: TxtComplViewModel
    // holds our Core Data managed object context (so we can delete stuff)
    @Environment(\.managedObjectContext) var moc
    // holds our dismiss action (so we can pop the view off the navigation stack)
    @Environment(\.dismiss) var dismissDetailView
    // holds boolean value on whether the txt input field is active
    @FocusState var isInputActive: Bool
    // create an object that manages the data(the logic) of ListDetailView layout
    
    @State private var isSearchViewPresented: Bool = false

    var body: some View {
        TextInputView(isLoading: $txtComplVM.loading, pen: $txtComplVM.sessionStory)
            .onAppear {
                self.txtComplVM.sessionStory = story.wrappedComplStory
            }
            .focused($isInputActive)
            .fullScreenCover(isPresented: $viewModel.isShowingNewPageScreen, onDismiss: {
                dismissDetailView()
            },content: {
                NavigationView {
                    NewPageView()
                }
            })
            .sheet(isPresented: $viewModel.isShareViewPresented, onDismiss: {
                debugPrint("Dismiss")
            }, content: {
                ActivityViewController(itemsToShare: [storyToShare()]) //[URL(string: "https://www.swifttom.com")!]
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditorToolbar(showNewPage: $viewModel.isShowingNewPageScreen.onChange(launchNewPage),
                              presentExportView: $viewModel.isShowingPromptEditorScreen,
                              presentShareView: $viewModel.isShareViewPresented,
                              showPromptEditor: $viewModel.isShowingPromptEditorScreen,
                              sendingContent: $viewModel.isSendingContent.onChange(sendToStoryMaker),
                              keyboardActive: _isInputActive)

                submitToolbarButton
                
                keyboardToolbarButtons
            }
            .disabled(txtComplVM.loading) // when loading users can't interact with this view.
    }
    
    var submitToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
//            if isInputActive {
//                Button(action: sendToStoryMaker, label: { Image(systemName: "arrow.up.circle") })
//                    .padding(.trailing)
//                    .buttonStyle(.plain)
//            }
        }
    }
    
    var keyboardToolbarButtons: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            GenrePickerView(genreChoices: $txtComplVM.setGenre)
                .padding(.trailing)
            Button(action: hideKeyboardAndSave, label: { Image(systemName: "keyboard.chevron.compact.down") })
        }
    }
}
