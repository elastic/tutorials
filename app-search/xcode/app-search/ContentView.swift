//
//  ContentView.swift
//  app-search
//
//  Created by Ethan Groves on 3/5/21.
//

import SwiftUI

struct ContentView: View {
  // @State variables are special variables that are automatically monitored for changes, and will update any UI elements that contain references
  @State var results: [Result] = []
  @State private var searchText = ""
  @State private var showCancelButton: Bool = false
  private let TmdbApiKey = "my_tmdb_api_key"
  
  //------------------------------------
  // The main body of the UI
  //------------------------------------
  var body: some View {
    VStack(alignment: .leading) {
      
      //--------------------------------
      // Search bar
      //--------------------------------
      HStack {
        HStack {
          Image(systemName: "magnifyingglass")
          TextField("search", text: $searchText, onEditingChanged: { isEditing in
            // Set Bool to show the cancel button whenever there is text in the field
            self.showCancelButton = true
          }, onCommit: {
            // When a search is submitted, send it to App Search and get the results
            AppSearch().getResults(searchTerm: searchText) { (results) in
              self.results = results
            }
          })
          // Display a small 'x' button in the text field which can clear all text
          Button(action: {
            self.searchText = ""
          }) {
            Image(systemName: "xmark.circle.fill").opacity(searchText == "" ? 0 : 1)
          }
        }
        // Formatting and styling for the search bar
        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        .foregroundColor(.secondary)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10.0)
        
        // Display a 'Cancel' button to clear text whenever there is text in the TextField
        if showCancelButton {
          Button("Cancel") {
            UIApplication.shared.endEditing()
            self.searchText = ""
            self.showCancelButton = false
          }
        }
      }
      // Formatting and styling for the 'Cancel' button
      .padding(.horizontal)

      //--------------------------------
      // Table containing search results
      //--------------------------------
      List(results) { result in
        // For each search result returned from App Search, build a simple UI element
        HStack {
          // If the search results contain a URL path for a movie poster, use that for the image
          // Otherwise, grab a random image from http://source.unsplash.com
          if result.posterPath.raw != nil {
            let imageURL = "https://image.tmdb.org/t/p/w500" + result.posterPath.raw! + "?api_key=" + TmdbApiKey
            AsyncImage(
              url: URL(string: imageURL)!,
              placeholder: { Text("Loading...")},
              image: { Image(uiImage: $0).resizable() }
            )
            // Formatting and styling for the image
            .aspectRatio(contentMode: .fit)
            .frame(width: 100)
          } else {
            let imageURL = "https://source.unsplash.com/user/jakobowens1/100x150?" + String(Int.random(in: 1..<930))
            AsyncImage(
              url: URL(string: imageURL)!,
              placeholder: { Text("Loading...")},
              image: { Image(uiImage: $0).resizable() }
            )
            // Formatting and styling for the image
            .aspectRatio(contentMode: .fit)
            .frame(width: 100)
          }

          // Display the movie title and description
          VStack {
            Text(result.title.raw!)
              // Formatting and styling for the title
              .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
              .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
            Text(result.overview.raw!)
              // Formatting and styling for the description
              .font(.caption)
              .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 1.0))
          }
          // Formatting and styling for the title and description container
          .frame(height: 150)
        }
        // Formatting and styling for the search results container
        .frame(alignment: .topLeading)
      }
    }
  }
}

// This struct is used for generating a preview in Xcode
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

// A simple function for removing "focus" from (i.e. unselecting) a UI element
extension UIApplication {
  func endEditing() {
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
