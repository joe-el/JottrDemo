//
//  StoryListView.swift
//  JottrDemo
//
//  Created by Kenneth Gutierrez on 10/7/22.
//

import Foundation
import SwiftUI

struct ContentListView: View {
    // MARK: Properties
    
    // retrieve the txtcompl view model from the environment
    @EnvironmentObject var txtComplVM: TxtComplViewModel
    // retrieve the story list view model where the data is managed
    @StateObject private var viewModel = ContentListViewVM()
    // retrieve our Core Data managed object context (so we can delete or save stuff)
    @Environment(\.managedObjectContext) var moc
    // fetch the Story entity in Core Data
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "dateCreated", ascending: false)]) var stories: FetchedResults<Story>
    @State private var listOfStories: [Story] = []
    // toggle it to get the past seven days of stories or all of it
    @Binding var isShowingRecentList: Bool
    // toggle it to get the contents sent to trash list
    @Binding var isShowingTrashList: Bool
    
    var body: some View {
        List {
            // for each story in the array, create a listing row. added as modifier the swipe to delete feature
            ForEach(listOfStories, id: \.self) { item in // content: StoryListRowView.init
                StoryListRowView(story: item, showTrashBin: $isShowingTrashList)
            }
            .onDelete(perform: isShowingTrashList ? deleteStory : removeFromList)
        }
        .onAppear {
            self.listOfStories = coreDataContent
        }
        .fullScreenCover(isPresented: $viewModel.isShowingStoryEditorScreen, onDismiss: {
            self.isShowingRecentList = false
        }, content: {
            NavigationView {
                NewPageView()
            }
        })
        .fullScreenCover(isPresented: $viewModel.isShowingSearchScreen) { SearchView() }
        .fullScreenCover(isPresented: $viewModel.isShowingAccountScreen) { AccountView() }
        .navigationTitle(pageTitle())
        .toolbar {
            MainToolbar(isShowingNewPage: $viewModel.isShowingStoryEditorScreen, isShowingAccount: $viewModel.isShowingAccountScreen)
        }
        .overlay(MagnifyingGlass(showSearchScreen: $viewModel.isShowingSearchScreen), alignment: .bottomTrailing)
    }
    
    // either showing all the content in CoreData or the last seven days
    var coreDataContent: [Story] {
        get {
            var fetchedStories: [Story] = []
            
            if !isShowingRecentList {
                fetchedStories.append(contentsOf: stories)
            } else if isShowingRecentList {
                // filter returns stories from the last seven days.
                let sortedByDate = stories.filter {
                    guard let unwrappedValue = $0.dateCreated else {
                        return false
                    }
                    return unwrappedValue > (Date.now - 604_800) // 604800 sec. is seven days in seconds
                }
                fetchedStories.append(contentsOf: sortedByDate)
            } else if isShowingTrashList {
                let discardedContent = stories.filter {
                    return $0.wrappedIsDiscarded
                }
                fetchedStories.append(contentsOf: discardedContent)
            }
            
            return fetchedStories
        }
    }
    
    private func removeFromList(at offsets: IndexSet) {
        for offset in offsets {
            let story = stories[offset]
            
            //update the saved story
            moc.performAndWait {
                story.isDiscarded = true
                story.dateDiscarded = Date.now
                PersistenceController.shared.saveContext()
            }
            
            listOfStories.remove(at: offset)
        }
    }
    // TODO: Add a Timer of 30 Days Of Auto Delete
    private func deleteStory(at offsets: IndexSet) {
        for offset in offsets {
            let story = stories[offset]
            // delete from the list
            listOfStories.remove(at: offset)
            // delete from in memory storage
            moc.delete(story)
        }

        // write the changes out to persistent storage
        PersistenceController.shared.saveContext()
    }
}
