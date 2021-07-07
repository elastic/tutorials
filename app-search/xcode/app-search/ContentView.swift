//
//  ContentView.swift
//  app-search
//
//  Created by Ethan Groves on 3/5/21.
//

import SwiftUI

struct ContentView: View {
  @State var results: [Result] = []
  @State private var searchText = ""
  @State private var showCancelButton: Bool = false
  private let TmdbApiKey = "my_tmdb_api_key"
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        HStack {
          Image(systemName: "magnifyingglass")
          TextField("search", text: $searchText, onEditingChanged: { isEditing in
            self.showCancelButton = true
          }, onCommit: {
            AppSearch().getResults(searchTerm: searchText) { (results) in
              self.results = results
            }
          })
          Button(action: {
            self.searchText = ""
          }) {
            Image(systemName: "xmark.circle.fill").opacity(searchText == "" ? 0 : 1)
          }
        }
        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        .foregroundColor(.secondary)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10.0)
        
        if showCancelButton {
          Button("Cancel") {
            UIApplication.shared.endEditing()
            self.searchText = ""
            self.showCancelButton = false
          }
        }
      }
      .padding(.horizontal)

      List(results) { result in
        HStack {
          if result.posterPath.raw != nil {
            let imageURL = "https://image.tmdb.org/t/p/w500" + result.posterPath.raw! + "?api_key=" + TmdbApiKey
            AsyncImage(
              url: URL(string: imageURL)!,
              placeholder: { Text("Loading...")},
              image: { Image(uiImage: $0).resizable() }
            )
            .aspectRatio(contentMode: .fit)
            .frame(width: 100)
          } else {
            let imageURL = "https://source.unsplash.com/user/jakobowens1/100x150?" + String(Int.random(in: 1..<930))
            AsyncImage(
              url: URL(string: imageURL)!,
              placeholder: { Text("Loading...")},
              image: { Image(uiImage: $0).resizable() }
            )
            .aspectRatio(contentMode: .fit)
            .frame(width: 100)
          }

          VStack {
            Text(result.title.raw!)
              .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
              .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
            Text(result.overview.raw!)
              .font(.caption)
              .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4, opacity: 1.0))
          }.frame(height: 150)
        }.frame(alignment: .topLeading)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

extension UIApplication {
  func endEditing() {
    sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
