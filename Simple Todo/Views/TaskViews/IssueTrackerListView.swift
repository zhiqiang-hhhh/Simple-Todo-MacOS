//
//  IssueTrackerListView.swift
//  Simple Todo
//
//  Created by Subkhan Sarif on 04/07/23.
//

import SwiftUI

struct IssueTrackerListView: View {
    @EnvironmentObject var taskDelegate: TaskDelegate
    @EnvironmentObject var navigationState: MyNavigationState
    @EnvironmentObject var jiraController: JiraController
    @State var isLoading: Bool = false
    @State var taskList: [MyJiraTaskItem] = []
    @State var message: String = ""
    @State var shouldShowToast: Bool = false
    @State var createdTask: TaskModel? = nil
    
    @State var isSearching: Bool = false
    @State var searchKey: String = ""
    
    var body: some View {
        VStack {
            MyNavigationBar {
                HStack{
                    Text("Issue Tracker")
                        .frame(maxWidth: .infinity)
                    Button {
                        withAnimation {
                            isSearching.toggle()
                        }
                    } label: {
                        if isSearching {
                            Image(systemName: "xmark")
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .buttonStyle(.plain)
                    if isSearching {
                        TextField("Search Key", text: $searchKey)
                            .textFieldStyle(.plain)
                            .padding(defaultPadding)
                            .background(ColorTheme.instance.textInactive.opacity(0.5))
                            .cornerRadius(4)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            } onBackButton: {
                navigationState.pop()
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                issueItem
            }
        }
        .frame(minWidth: 600)
        .onAppear {
            isLoading = true
            jiraController.getMyTaskList { myTasks in
                isLoading = false
                taskList = myTasks ?? []
            }
        }
    }
    
    var tableHeader: some View {
        HStack {
            HStack {
                Text("Key")
            }
            .frame(maxWidth: 60, alignment: .leading)
            
            HStack {
                Text("Summary")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("Status")
            }
            .frame(maxWidth: 100, alignment: .leading)
            
            
            HStack {
                Text("Action")
            }
            .frame(maxWidth: 110, alignment: .leading)
            
        }
        .padding(defaultPadding)
    }
    
    var issueItem: some View {
        VStack {
            tableHeader
            
            Divider()
            
            ForEach(taskList, id: \.id) { task in
                if let taskKey = task.key {
                    HStack {
                        HStack {
                            Text(taskKey)
                        }
                        .frame(maxWidth: 60, alignment: .leading)
                        
                        HStack {
                            Text(task.summary ?? "")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            if let status = task.status?.name {
                                Text(status.uppercased())
                                    .font(.system(size: 10))
                                    .foregroundColor(ColorTheme.instance.textDefault)
                                    .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                                    .background(ColorTheme.instance.textButtonInactive.opacity(0.5))
                                    .cornerRadius(4)
                            }
                        }
                        .frame(maxWidth: 100, alignment: .leading)
                        
                        actionLink(jiraTask: task)
                            .frame(maxWidth: 120, alignment: .leading)
                        
                    }
                }
            }
        }
        .padding(defaultPadding)
        .background(ColorTheme.instance.textInactive.opacity(0.2))
        .cornerRadius(8)
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
        
    }
    
    func actionLink(jiraTask: MyJiraTaskItem) -> AnyView {
        let (taskExists, task) = taskDelegate.hasTask(jiraId: jiraTask.key ?? "")
        
        return AnyView(
            HStack {
                if taskExists && task != nil {
                    MyNavigationLink(id: task!.id) {
                        HStack {
                            Text("Detail →")
                        }
                    } destination: {
                        TaskDetailView(id: task!.id, task: task!)
                    }
                } else {
                    MyMenuButton {
                        Text("New Task →")
                    } callback: {
                        createNewTask(jiraTask: jiraTask)
                    }
                    .buttonStyle(.plain)
                    if createdTask != nil {
                        MyNavigationLink(id: createdTask!.id) {
                            EmptyView()
                        } destination: {
                            TaskDetailView(id: createdTask!.id, task: createdTask!)
                        }
                        .frame(maxWidth: 0)
                    }
                }
            }
        )
    }
    
    
    func createNewTask(jiraTask: MyJiraTaskItem) {
        guard let key = jiraTask.key, let summary = jiraTask.summary else {
            return
        }
        
        let task = TaskModel(
            title: summary,
            timestamp: "")
        
        isLoading = true
        jiraController.loadIssueDetail(by: key) { jiraDetail in
            isLoading = false
            guard let detail = jiraDetail else {
                message = "Issue not found: \(key)"
                withAnimation {
                    shouldShowToast = true
                }
                return
            }
            task.setJiraCard(key)
            task.jiraStatus = detail.status
            save(task: task)
        }
    }
    
    func save(task: TaskModel) {
        createdTask = task
        taskDelegate.saveTask(task)
        navigationState.push(id: task.id)
    }
}

struct IssueTrackerListView_Previews: PreviewProvider {
    static var previews: some View {
        IssueTrackerListView()
            .environmentObject(MyNavigationState())
            .environmentObject(JiraController.instance)
            .environmentObject(TaskDelegate.instance)
    }
}
