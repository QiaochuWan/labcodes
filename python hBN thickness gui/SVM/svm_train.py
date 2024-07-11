#!/usr/bin/env python
# coding: utf-8

# In[ ]:


def TrainSVM(path1, C_par, gamma_par, TrainSize_par, TestSize_par):
    import numpy as np
    from sklearn import svm
    import matplotlib.pyplot as plt
    from sklearn.model_selection import train_test_split
    import matplotlib as mpl
    from scipy import io
    from scipy.io import savemat
    import joblib
    
    data1 = io.loadmat(path1 + "Contrast2.mat")
    data1 = data1['AllCon']
    RGB_data = data1[0:3, :]
    label_data = data1[4, :]
    
    RGB_data = np.transpose(RGB_data)
    train_data, test_data, train_label, test_label = train_test_split(RGB_data, label_data, random_state=1, train_size = TrainSize_par, test_size = TestSize_par)
    
    svm_model = svm.SVC(C=C_par, kernel='rbf', gamma=gamma_par, decision_function_shape='ovr')
    svm_model.fit(train_data, train_label)
    
    ScoreDic = {"TrainScore": svm_model.score(train_data, train_label), "TestScore": svm_model.score(test_data, test_label)}
    savemat(path1+"Score.mat", ScoreDic)
    
    R_min, R_max = RGB_data[:,0].min(), RGB_data[:,0].max()
    G_min, G_max = RGB_data[:,1].min(), RGB_data[:,1].max()
    B_min, B_max = RGB_data[:,2].min(), RGB_data[:,2].max()
    R_ = np.linspace(R_min, R_max, 50)
    G_ = np.linspace(G_min, G_max, 50)
    B_ = np.linspace(B_min, B_max, 50)
    Rs, Gs, Bs = np.meshgrid(R_, G_, B_, indexing='ij')
    assert np.all(Rs[:,0,0] == R_)
    assert np.all(Gs[0,:,0] == G_)
    assert np.all(Bs[0,0,:] == B_)
    
    grid_test = np.stack((Rs.flat, Gs.flat, Bs.flat), axis=1)
    grid_hat = svm_model.predict(grid_test)
    grid_hat = grid_hat.reshape(Rs.shape)
    
    
    mdic1 = {"Rs": Rs, "Gs" : Gs, "Bs" : Bs, "grid_hat" : grid_hat, "RGB_data" : RGB_data, "label_data" : label_data}
    savemat(path1 + "SVM_results.mat", mdic1)
    joblib.dump(svm_model, path1 + 'svm_model.m')

